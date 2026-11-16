# Nuvio Launcher — Accounts contract (app ⇄ website)

The launcher supports three account types, stored side by side (multi-account):

| Type | Who authenticates | Used in game |
| --- | --- | --- |
| `microsoft` | Microsoft → Xbox Live → XSTS → Minecraft Services | real Minecraft token, works on every server |
| `nuvio` | Nuvio website (device link) + Yggdrasil server in the website | via **authlib-injector**; custom skin/cape visible to yourself, in your own worlds/LAN and to other Nuvio-launcher players |
| `local` | nobody (offline) | offline UUID, no skin |

## 1. Microsoft (device-code flow, no redirect URI needed)

Client id comes from `--dart-define=MS_CLIENT_ID=<azure application (client) id>`.
The Azure app must be a *public client* (“Allow public client flows” = yes), supported account type
“Personal Microsoft accounts” (or “…and organizational”), and must be **approved by Mojang** for the
Minecraft Services API, otherwise `login_with_xbox` answers 403 “Invalid app registration”.

1. `POST https://login.microsoftonline.com/consumers/oauth2/v2.0/devicecode`
   form: `client_id`, `scope=XboxLive.signin offline_access`
   → `device_code`, `user_code`, `verification_uri`, `expires_in`, `interval`. Show code, open the URI.
2. Poll `POST https://login.microsoftonline.com/consumers/oauth2/v2.0/token`
   form: `grant_type=urn:ietf:params:oauth:grant-type:device_code`, `client_id`, `device_code`.
   While `error == authorization_pending` keep polling (respect `interval`, `slow_down` ⇒ +5 s);
   `authorization_declined`, `expired_token` ⇒ stop. Success ⇒ `access_token`, `refresh_token`.
3. Xbox Live: `POST https://user.auth.xboxlive.com/user/authenticate`
   JSON `{"Properties":{"AuthMethod":"RPS","SiteName":"user.auth.xboxlive.com","RpsTicket":"d=<access_token>"},"RelyingParty":"http://auth.xboxlive.com","TokenType":"JWT"}`
   (headers `Content-Type`, `Accept: application/json`) → `Token`, `DisplayClaims.xui[0].uhs`.
4. XSTS: `POST https://xsts.auth.xboxlive.com/xsts/authorize`
   JSON `{"Properties":{"SandboxId":"RETAIL","UserTokens":["<xbl token>"]},"RelyingParty":"rp://api.minecraftservices.com/","TokenType":"JWT"}`
   → `Token`, `DisplayClaims.xui[0].uhs`. HTTP 401 carries `XErr`:
   `2148916233` no Xbox account, `2148916235` Xbox unavailable in this country,
   `2148916236`/`2148916237` adult verification required, `2148916238` child account (needs family).
5. Minecraft: `POST https://api.minecraftservices.com/authentication/login_with_xbox`
   JSON `{"identityToken":"XBL3.0 x=<uhs>;<xsts token>"}` → `access_token`, `expires_in` (≈ 24 h).
6. Entitlement: `GET https://api.minecraftservices.com/entitlements/mcstore` (Bearer MC token)
   → `items[].name` containing `product_minecraft` or `game_minecraft` ⇒ owns Java Edition.
   No item ⇒ “account has no Minecraft Java license” (keep account listed but mark `ownsJava=false`, block Play).
7. Profile: `GET https://api.minecraftservices.com/minecraft/profile` → `id` (32 hex), `name`,
   `skins[] {id,state,url,variant}`, `capes[]`. HTTP 404 ⇒ owns game but has no profile yet.
8. Refresh: repeat step 2 with `grant_type=refresh_token`, `client_id`, `refresh_token`,
   `scope=XboxLive.signin offline_access`, then steps 3–7. Refresh automatically when the MC token
   expires in < 5 min or on any 401. A refresh failure with `invalid_grant` ⇒ account `needsRelogin`.

Store refresh tokens in the platform secure store (Android Keystore / Windows credential store),
never in plain `shared_preferences`.

## 2. Nuvio Account (device link)

Base URL = `NUVIO_API_BASE`. All responses `{ ok, ... }` as in `docs/API.md`.

### `POST /api/account/device/start`
```json
{ "ok": true, "deviceCode": "opaque-secret-40-chars", "userCode": "ABCD-EFGH",
  "verificationUrl": "https://site/account/link?code=ABCD-EFGH", "expiresIn": 600, "interval": 3 }
```
Launcher opens `verificationUrl` in the browser (url_launcher, external) and polls.

### `POST /api/account/device/poll`  body `{ "deviceCode": "…" }`
* pending → `{ "ok": true, "status": "pending" }`
* approved → `{ "ok": true, "status": "approved", "accessToken": "…", "profile": Profile }`
* denied → `{ "ok": false, "code": "ACCESS_DENIED", "message": "…" }`
* expired → `{ "ok": false, "code": "DEVICE_CODE_EXPIRED", "message": "…" }`

### `GET /api/account/me`  header `Authorization: Bearer <accessToken>`
→ `{ "ok": true, "profile": Profile }`, or HTTP 401 `{ "ok": false, "code": "TOKEN_INVALID" }`.
Call it at startup and before launching; 401 ⇒ account `needsRelogin`.

### `POST /api/account/logout`  Bearer → `{ "ok": true }` (revokes the token)

### Profile
```json
{ "id": "32 hex chars, no dashes", "username": "Steve", "name": "Steve",
  "displayName": "Steve", "badge": true,
  "model": "classic|slim", "skinUrl": "https://site/api/textures/<hash>.png|null",
  "capeUrl": "https://site/api/textures/<hash>.png|null" }
```
`name` is the real in-game name (`--username`) = the plain username. The Nuvio badge is a logo glyph, not text:
usernames are 3–16 characters `[A-Za-z0-9_]`; servers with the NuvioSkins plugin render the logo before the name (nametag, tab, chat, per the player's HUD settings: `hud {nametag, tab, chat}`).
`displayName` is what the UI shows.

### Launching a Nuvio account (authlib-injector)
1. Ensure `authlib-injector.jar` is in the launcher data dir. Download metadata from
   `GET https://authlib-injector.yushi.moe/artifact/latest.json` → `download_url`, `checksums.sha256`.
2. JVM arg **before** `-cp`: `-javaagent:<path-to-jar>=<NUVIO_API_BASE>/api/yggdrasil`
   (also add `-Dauthlibinjector.side=client`).
3. Game args: `--username <profile.name> --uuid <profile.id> --accessToken <accessToken> --userType mojang`.

The Yggdrasil root `<NUVIO_API_BASE>/api/yggdrasil` implements the authlib-injector API
(metadata, `authserver/*`, `sessionserver/*`), so skins/capes, singleplayer and LAN between Nuvio
launcher players work. Public servers validate against Mojang, so seeing the skin/cape there needs a
server-side plugin (not part of this project).

## 3. Local account
`{ type: local, username }` → existing offline UUID (`OfflinePlayer:<name>` MD5 v3). No network.

## 4. Content providers
* **Modrinth** (no key): `https://api.modrinth.com/v2` — `/search?query=&facets=[["project_type:mod"],["versions:1.21"],["categories:fabric"]]&limit=20&offset=`,
  `/project/{id}/version?game_versions=["1.21"]&loaders=["fabric"]` → `files[] {url, filename, hashes{sha1,sha512}, primary}`.
  Send `User-Agent: KazamaTech/NuvioLauncher/<version>`.
* **CurseForge** (needs key, `--dart-define=CURSEFORGE_API_KEY=…`, header `x-api-key`): `https://api.curseforge.com/v1`
  gameId `432`; classIds: mods `6`, resource packs `12`, worlds `17`, modpacks `4471`, shaders `6552`.
  `/mods/search?gameId=432&classId=&searchFilter=&gameVersion=&modLoaderType=&pageSize=20&index=`,
  `/mods/{id}/files?gameVersion=&modLoaderType=` → `downloadUrl` (may be null when the author disabled
  third-party downloads ⇒ show “open on CurseForge”). Hide CurseForge when no key is set.
* Install targets inside an instance dir: mods → `mods/`, shaders → `shaderpacks/`,
  resource packs → `resourcepacks/`, worlds (zip) → extract into `saves/`, modpacks (`.mrpack`) → v2.
