package tech.kazama.nuvioskins;

import com.destroystokyo.paper.profile.PlayerProfile;
import com.destroystokyo.paper.profile.ProfileProperty;
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;
import org.bukkit.event.EventHandler;
import org.bukkit.event.EventPriority;
import org.bukkit.event.Listener;
import org.bukkit.event.player.AsyncPlayerPreLoginEvent;
import org.bukkit.plugin.java.JavaPlugin;

/**
 * Applies the skin/cape of Nuvio accounts. Works by reading the signed texture property from the
 * Nuvio website (Yggdrasil-compatible) and adding it to the joining player's profile.
 * Only the textures are applied: the plugin never changes who is allowed to join.
 */
public final class NuvioSkinsPlugin extends JavaPlugin implements Listener {

    private record Cached(Optional<ProfileProperty> value, long expiresAt) {}

    private final Map<String, Cached> cache = new ConcurrentHashMap<>();
    private HttpClient http;
    private String root;
    private String prefix;
    private long ttlMs;
    private Duration timeout;

    @Override
    public void onEnable() {
        saveDefaultConfig();
        String site = getConfig().getString("site-url", "").replaceAll("/+$", "");
        prefix = getConfig().getString("name-prefix", "[Nuvio]");
        ttlMs = getConfig().getLong("cache-seconds", 300) * 1000L;
        timeout = Duration.ofSeconds(getConfig().getLong("timeout-seconds", 4));
        if (site.isEmpty() || site.contains("example.com")) {
            getLogger().warning("Set site-url in config.yml to your Nuvio website, then restart.");
            return;
        }
        root = site + "/api/yggdrasil";
        http = HttpClient.newBuilder().connectTimeout(timeout).build();
        getServer().getPluginManager().registerEvents(this, this);
        getLogger().info("Nuvio skins enabled for names starting with " + prefix);
    }

    // Runs off the main thread, so blocking HTTP is fine here.
    @EventHandler(priority = EventPriority.LOWEST)
    public void onPreLogin(AsyncPlayerPreLoginEvent event) {
        String name = event.getName();
        if (!name.startsWith(prefix)) return;
        Optional<ProfileProperty> textures = lookup(name);
        if (textures.isEmpty()) return;
        PlayerProfile profile = event.getPlayerProfile();
        profile.setProperty(textures.get());
        event.setPlayerProfile(profile);
    }

    private Optional<ProfileProperty> lookup(String name) {
        long now = System.currentTimeMillis();
        Cached hit = cache.get(name);
        if (hit != null && hit.expiresAt() > now) return hit.value();
        Optional<ProfileProperty> value = Optional.empty();
        try {
            value = fetch(name);
        } catch (Exception e) {
            getLogger().fine("Lookup failed for " + name + ": " + e.getMessage());
        }
        cache.put(name, new Cached(value, now + ttlMs));
        return value;
    }

    private Optional<ProfileProperty> fetch(String name) throws Exception {
        JsonArray names = new JsonArray();
        names.add(name);
        HttpResponse<String> ids = http.send(
            HttpRequest.newBuilder(URI.create(root + "/api/profiles/minecraft"))
                .timeout(timeout)
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(names.toString()))
                .build(),
            HttpResponse.BodyHandlers.ofString());
        if (ids.statusCode() != 200) return Optional.empty();
        JsonArray found = JsonParser.parseString(ids.body()).getAsJsonArray();
        if (found.isEmpty()) return Optional.empty();
        String id = found.get(0).getAsJsonObject().get("id").getAsString();

        HttpResponse<String> prof = http.send(
            HttpRequest.newBuilder(URI.create(root + "/sessionserver/session/minecraft/profile/" + id + "?unsigned=false"))
                .timeout(timeout).GET().build(),
            HttpResponse.BodyHandlers.ofString());
        if (prof.statusCode() != 200) return Optional.empty();
        JsonObject body = JsonParser.parseString(prof.body()).getAsJsonObject();
        JsonElement props = body.get("properties");
        if (props == null || !props.isJsonArray()) return Optional.empty();
        for (JsonElement el : props.getAsJsonArray()) {
            JsonObject p = el.getAsJsonObject();
            if ("textures".equals(p.get("name").getAsString())) {
                String sig = p.has("signature") ? p.get("signature").getAsString() : null;
                return Optional.of(new ProfileProperty("textures", p.get("value").getAsString(), sig));
            }
        }
        return Optional.empty();
    }
}
