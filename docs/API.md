# Nuvio Launcher — API Contract (app ⇄ website)

Base URL is configured at build time in the app with
`--dart-define=NUVIO_API_BASE=https://your-domain` (default `http://localhost:3000`).
All bodies are JSON (`Content-Type: application/json`). All responses carry `ok: boolean`.

Error shape (HTTP 4xx/5xx):

```json
{ "ok": false, "code": "LICENSE_NOT_FOUND", "message": "Human readable message" }
```

Error codes: `INVALID_REQUEST`, `LICENSE_NOT_FOUND`, `LICENSE_REVOKED`, `LICENSE_EXPIRED`,
`DEVICE_LIMIT_REACHED`, `DEVICE_NOT_ACTIVATED`, `RATE_LIMITED`, `SERVER_ERROR`.

## GET `/api/releases/latest`

Public. Latest published release (cached ~5 min on the server). The repository itself is never exposed.

```json
{
  "ok": true,
  "version": "0.1.0-beta.1",
  "prerelease": true,
  "publishedAt": "2026-11-12T08:00:00Z",
  "notes": "Markdown release notes",
  "platforms": {
    "windows": { "label": "Windows 10/11 (installer)", "size": 54321000, "url": "/api/download/windows" },
    "android": { "label": "Android 6.0+ (universal APK)", "size": 61234000, "url": "/api/download/android" }
  }
}
```

`url` is relative to the base URL. Downloads are streamed through the website, never redirected to GitHub.

## POST `/api/license/activate`

```json
{ "key": "NUVIO-XXXX-XXXX-XXXX", "deviceId": "uuid-v4-generated-once-per-install",
  "deviceName": "DESKTOP-ABC", "platform": "windows|android|macos", "appVersion": "0.1.0-beta.1" }
```

Success:

```json
{ "ok": true,
  "license": { "keyMasked": "NUVIO-XXXX-••••-A1B2", "plan": "plus", "features": ["plus"],
               "expiresAt": null, "maxDevices": 2, "devicesUsed": 1 },
  "checkedAt": "2026-11-12T08:00:00Z" }
```

## POST `/api/license/validate`

Body: `{ "key", "deviceId", "appVersion" }` → same success shape as activate.
The app re-validates at startup and every 24h. Offline grace period: **7 days** since last `checkedAt`.

## POST `/api/license/deactivate`

Body: `{ "key", "deviceId" }` → `{ "ok": true }`. Frees one device slot.

## GET `/api/announcements`

Public. Active announcements, newest first (max 10).

```json
{ "ok": true, "items": [ { "id": "cuid", "title": "…", "body": "…", "level": "info|warning|success", "createdAt": "ISO" } ] }
```

## Product rules

* **Free**: everything except the items below.
* **Nuvio Plus** (license feature `plus`): more than 3 instances, custom accent themes, per-instance JVM profiles.
* License key format: `NUVIO-` + 3 groups of 4 chars from `ABCDEFGHJKLMNPQRSTUVWXYZ23456789`.
