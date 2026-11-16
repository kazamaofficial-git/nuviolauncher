package tech.kazama.nuvioskins;

import com.destroystokyo.paper.profile.PlayerProfile;
import com.destroystokyo.paper.profile.ProfileProperty;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import io.papermc.paper.chat.ChatRenderer;
import io.papermc.paper.event.player.AsyncChatEvent;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.security.MessageDigest;
import java.time.Duration;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import net.kyori.adventure.key.Key;
import net.kyori.adventure.text.Component;
import net.kyori.adventure.text.format.NamedTextColor;
import org.bukkit.Bukkit;
import org.bukkit.entity.Player;
import org.bukkit.event.EventHandler;
import org.bukkit.event.EventPriority;
import org.bukkit.event.Listener;
import org.bukkit.event.player.AsyncPlayerPreLoginEvent;
import org.bukkit.event.player.PlayerJoinEvent;
import org.bukkit.event.player.PlayerQuitEvent;
import org.bukkit.plugin.java.JavaPlugin;
import org.bukkit.scoreboard.Scoreboard;
import org.bukkit.scoreboard.Team;

/**
 * Nuvio accounts on a Paper server: applies the signed skin/cape and shows the Nuvio logo badge
 * (a font glyph delivered by a tiny resource pack) in the nametag, tab list and chat, following the
 * HUD choices the player made on the Nuvio website. Only cosmetics - it never decides who may join.
 */
public final class NuvioSkinsPlugin extends JavaPlugin implements Listener {

    private static final Key FONT = Key.key("nuvio", "badge");
    /** Private-use character mapped to the Nuvio logo by the resource pack. */
    private static final String GLYPH = "";

    private record Info(String id, String name, boolean badge, boolean nametag, boolean tab, boolean chat,
                         ProfileProperty textures) {}

    private record Cached(Optional<Info> value, long expiresAt) {}

    private final Map<String, Cached> cache = new ConcurrentHashMap<>();
    private final Map<UUID, Info> online = new ConcurrentHashMap<>();
    private HttpClient http;
    private String site;
    private long ttlMs;
    private Duration timeout;
    private volatile byte[] packSha1;

    @Override
    public void onEnable() {
        saveDefaultConfig();
        site = getConfig().getString("site-url", "").replaceAll("/+$", "");
        ttlMs = getConfig().getLong("cache-seconds", 300) * 1000L;
        timeout = Duration.ofSeconds(getConfig().getLong("timeout-seconds", 4));
        if (site.isEmpty() || site.contains("example.com")) {
            getLogger().warning("Set site-url in config.yml to your Nuvio website, then restart.");
            return;
        }
        http = HttpClient.newBuilder().connectTimeout(timeout).build();
        getServer().getPluginManager().registerEvents(this, this);
        if (getConfig().getBoolean("send-badge-pack", true)) {
            Bukkit.getScheduler().runTaskAsynchronously(this, this::loadPackHash);
        }
        getLogger().info("Nuvio skins & badge enabled.");
    }

    @Override
    public void onDisable() {
        for (Team t : Bukkit.getScoreboardManager().getMainScoreboard().getTeams()) {
            if (t.getName().startsWith("nvb")) t.unregister();
        }
    }

    // ── Login: skin & cape (runs off the main thread, blocking HTTP is fine) ──

    @EventHandler(priority = EventPriority.LOWEST)
    public void onPreLogin(AsyncPlayerPreLoginEvent event) {
        Optional<Info> info = lookup(event.getName());
        if (info.isEmpty() || info.get().textures() == null) return;
        PlayerProfile profile = event.getPlayerProfile();
        profile.setProperty(info.get().textures());
        event.setPlayerProfile(profile);
    }

    // ── Join: badge in nametag/tab and the resource pack with the logo glyph ──

    @EventHandler
    public void onJoin(PlayerJoinEvent event) {
        Player player = event.getPlayer();
        // Everyone gets the pack so that every player can see the badge of Nuvio players.
        if (packSha1 != null) {
            player.setResourcePack(site + "/nuvio-badge-pack.zip", packSha1, false);
        }
        Optional<Info> info = lookup(player.getName());
        if (info.isEmpty() || !info.get().badge()) return;
        Info i = info.get();
        online.put(player.getUniqueId(), i);

        if (i.nametag()) {
            Scoreboard board = Bukkit.getScoreboardManager().getMainScoreboard();
            String teamName = "nvb" + Integer.toHexString(player.getName().toLowerCase().hashCode());
            Team team = board.getTeam(teamName);
            if (team == null) team = board.registerNewTeam(teamName);
            team.prefix(badge().append(Component.space()));
            team.addEntry(player.getName());
        }
        if (i.tab()) {
            player.playerListName(badge().append(Component.space()).append(Component.text(player.getName())));
        }
    }

    @EventHandler
    public void onQuit(PlayerQuitEvent event) {
        online.remove(event.getPlayer().getUniqueId());
    }

    @EventHandler(priority = EventPriority.LOW)
    public void onChat(AsyncChatEvent event) {
        Info i = online.get(event.getPlayer().getUniqueId());
        if (i == null || !i.chat()) return;
        ChatRenderer previous = event.renderer();
        event.renderer((source, name, message, viewer) ->
            badge().append(Component.space()).append(previous.render(source, name, message, viewer)));
    }

    private static Component badge() {
        return Component.text(GLYPH).font(FONT).color(NamedTextColor.WHITE);
    }

    // ── Website lookups ──

    private Optional<Info> lookup(String name) {
        long now = System.currentTimeMillis();
        Cached hit = cache.get(name);
        if (hit != null && hit.expiresAt() > now) return hit.value();
        Optional<Info> value = Optional.empty();
        try {
            value = fetch(name);
        } catch (Exception e) {
            getLogger().fine("Lookup failed for " + name + ": " + e.getMessage());
        }
        cache.put(name, new Cached(value, now + ttlMs));
        return value;
    }

    private String get(String url) throws Exception {
        HttpResponse<String> res = http.send(
            HttpRequest.newBuilder(URI.create(url)).timeout(timeout).GET().build(),
            HttpResponse.BodyHandlers.ofString());
        return res.statusCode() == 200 ? res.body() : null;
    }

    private Optional<Info> fetch(String name) throws Exception {
        String body = get(site + "/api/plugin/profile?name=" + java.net.URLEncoder.encode(name, "UTF-8"));
        if (body == null) return Optional.empty();
        JsonObject p = JsonParser.parseString(body).getAsJsonObject();
        if (!p.get("found").getAsBoolean()) return Optional.empty();
        String id = p.get("id").getAsString();
        JsonObject hud = p.getAsJsonObject("hud");

        ProfileProperty textures = null;
        String prof = get(site + "/api/yggdrasil/sessionserver/session/minecraft/profile/" + id + "?unsigned=false");
        if (prof != null) {
            var props = JsonParser.parseString(prof).getAsJsonObject().getAsJsonArray("properties");
            if (props != null) {
                for (var el : props) {
                    JsonObject o = el.getAsJsonObject();
                    if ("textures".equals(o.get("name").getAsString())) {
                        String sig = o.has("signature") ? o.get("signature").getAsString() : null;
                        textures = new ProfileProperty("textures", o.get("value").getAsString(), sig);
                    }
                }
            }
        }
        return Optional.of(new Info(id, p.get("name").getAsString(), p.get("badge").getAsBoolean(),
            hud.get("nametag").getAsBoolean(), hud.get("tab").getAsBoolean(), hud.get("chat").getAsBoolean(), textures));
    }

    private void loadPackHash() {
        try {
            HttpResponse<byte[]> res = http.send(
                HttpRequest.newBuilder(URI.create(site + "/nuvio-badge-pack.zip")).timeout(Duration.ofSeconds(30)).GET().build(),
                HttpResponse.BodyHandlers.ofByteArray());
            if (res.statusCode() == 200) {
                packSha1 = MessageDigest.getInstance("SHA-1").digest(res.body());
            }
        } catch (Exception e) {
            getLogger().warning("Could not load the badge pack hash: " + e.getMessage());
        }
    }
}
