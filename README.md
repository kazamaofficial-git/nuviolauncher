# Nuvio Launcher

Launcher Minecraft Java oleh **Kazama Tech** (beta) untuk Windows dan Android, plus website (landing, unduhan, akun Nuvio, konsol admin) dan plugin server untuk skin Nuvio.

```
app/      Flutter (Android + Windows, landscape-only, satu build gabungan)
web/      Next.js 15 + Prisma/SQLite: situs, API lisensi/rilis, akun Nuvio, server Yggdrasil, admin
plugin/   Plugin Paper "NuvioSkins" (buatan sendiri) agar skin/cape Nuvio terlihat di server
scripts/  skrip CI (konfigurasi platform, penandatanganan APK, installer Inno Setup)
docs/     kontrak API (API.md) dan akun (ACCOUNTS.md)
.github/  CI (ci.yml) dan rilis otomatis (release-app.yml)
```

## Website

```bash
cd web
cp .env.example .env        # isi SESSION_SECRET, ADMIN_EMAIL, ADMIN_PASSWORD_HASH (node scripts/hash-password.mjs <sandi>)
npm install
npx prisma migrate deploy   # atau: npx prisma db push
npm run dev                 # http://localhost:3000
```

Produksi: `docker compose up -d --build` (SQLite disimpan di volume). Variabel penting:
`NEXT_PUBLIC_SITE_URL`, `GITHUB_REPO` (format `owner/nama`, hanya di server) dan `GITHUB_TOKEN`
bila repo privat, `SMTP_*` (wajib di produksi untuk OTP email), `GOOGLE_CLIENT_ID/SECRET`
(opsional, redirect `<situs>/api/auth/google/callback`), `TEXTURES_DIR`.
Unduhan diproxy lewat situs sehingga alamat repositori tidak pernah sampai ke browser.
`/sitemap.xml` dan `/robots.txt` dibuat otomatis.

## Aplikasi

```bash
cd app
flutter create --platforms=android,windows --org com.kazamatech --project-name nuvio_launcher .
flutter pub get
flutter run -d windows \
  --dart-define=NUVIO_API_BASE=https://situs-anda \
  --dart-define=MS_CLIENT_ID=<azure-client-id> \
  --dart-define=CURSEFORGE_API_KEY=<opsional>
```

## Rilis (GitHub Actions)

Push tag `v*` (mis. `v0.1.0-beta.1`) atau jalankan manual. Workflow membuat installer Windows x64,
APK universal Android, jar plugin, `SHA256SUMS.txt`, lalu menerbitkannya ke GitHub Releases.

| Jenis | Nama | Fungsi |
| --- | --- | --- |
| Secret | `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` | tanda tangan APK (tanpa ini APK debug-signed) |
| Secret | `CURSEFORGE_API_KEY` | konten CurseForge |
| Variable | `NUVIO_API_BASE`, `MS_CLIENT_ID` | alamat situs, client id Azure |

## Login Microsoft
Daftarkan aplikasi di Azure (public client, akun pribadi) lalu ajukan persetujuan ke Mojang untuk Minecraft Services;
tanpa itu Mojang menjawab 403 "Invalid app registration". Detail: `docs/ACCOUNTS.md`.

## Batasan saat ini (jujur)
* Windows hanya x64/arm64 (Flutter tidak mendukung 32-bit); Android satu APK universal.
* HUD sentuh (sembunyikan, pengaturan, editor tata letak, auto-hide saat keyboard/mouse fisik dipakai, tanpa input ganda) sudah ada di app, tetapi baru bisa dipakai penuh setelah runtime Android ada.
* Peluncuran game baru di Windows. Android: UI, versi, instance, lisensi, akun, konten; runtime JVM + GL belum ada (lihat `docs/ANDROID_RUNTIME.md`).
* Loader Fabric/Quilt/Forge/NeoForge dan modpack (.mrpack + CurseForge) sudah ada di desktop, tetapi belum diuji di perangkat nyata. NeoForge: Minecraft 1.20.2+.
* Badge Nuvio adalah logo (glyph font dari resource pack kecil), bukan teks. Tampil di nametag/Tab/chat hanya di server dengan plugin `plugin/` (server offline-mode); di singleplayer/LAN tidak ada plugin sehingga yang tampil hanya nama.
* Protokol `nuvio://` terdaftar di Android; di Windows launcher tetap polling setelah login di browser.
* Kode belum pernah dikompilasi di lingkungan pembuatan ini; `ci.yml` akan menangkap galat pada run pertama.
