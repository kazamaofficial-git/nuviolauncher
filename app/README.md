# Nuvio Launcher — app (Flutter)

Minecraft launcher by **Kazama Tech** (beta). One codebase for Android and Windows; macOS is planned.
The UI is **landscape-only** on every platform.

## Layout

```
lib/
  core/        theme, constants, utils, shared neon widgets
  data/        models, services (HTTP, Mojang, game launcher), repositories (persistence)
  features/    home, versions, instances, license, settings, news, shell (navigation)
test/          unit tests (no platform channels)
```

## Platform folders are generated

`android/` and `windows/` are **not** committed. CI (and you, locally) generate them:

```bash
flutter create --platforms=android,windows --org com.kazamatech --project-name nuvio_launcher .
python3 ../scripts/configure_platforms.py android/app/src/main/AndroidManifest.xml
dart run flutter_launcher_icons -f flutter_launcher_icons-android.yaml   # atau -windows.yaml
```

## Run

```bash
flutter pub get
flutter run -d windows --dart-define=NUVIO_API_BASE=http://localhost:3000
flutter test
```

## What works (beta)

| Area | Windows | Android |
| --- | --- | --- |
| Versions (Mojang manifest), instances, settings | yes | yes |
| Nuvio Plus licence (activate / validate / deactivate) | yes | yes |
| Announcements and update check | yes | yes |
| Accounts: Microsoft (device code), Nuvio Account (authlib-injector), Local | yes | yes (login); launch not yet |
| Launch vanilla Minecraft Java | yes | not yet |
| Mod loaders, modpack hub, LAN host | roadmap | roadmap |

Free tier: 3 instances, 4 download threads. **Nuvio Plus**: unlimited instances, 16 download threads,
custom accent colours, per-instance JVM profiles.

## Builds

| Flag | Meaning |
| --- | --- |
| `--dart-define=NUVIO_API_BASE=https://your-domain` | Website/API base URL (licences, news, updates) |
| `--dart-define=MS_CLIENT_ID=<azure client id>` | Enables Microsoft login (see docs/ACCOUNTS.md) |
