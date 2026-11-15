# NuvioSkins (Paper plugin)

Plugin server buatan Kazama Tech — tanpa dependensi pihak ketiga selain Paper API.
Menampilkan skin & cape akun Nuvio kepada semua pemain di server.

## Cara kerja
Pemain Nuvio masuk dengan nama `[Nuvio]Username`. Saat login, plugin menanyakan website Nuvio
(`/api/yggdrasil`) dan menambahkan properti `textures` ke profil pemain. Pemain lain melihatnya
selama klien mereka juga memakai Nuvio Launcher (authlib-injector mengizinkan domain tekstur situs).

## Pasang
1. Build: `mvn -B package` → `target/NuvioSkins-<versi>.jar` (CI juga melampirkannya di Release).
2. Taruh di `plugins/` server Paper 1.20.4+ (Java 17+), jalankan sekali, lalu isi `site-url` di `plugins/NuvioSkins/config.yml`.

## Batasan
* Server harus `online-mode=false` (atau di belakang proxy yang menerima akun Nuvio), karena akun Nuvio tidak
  divalidasi oleh Mojang. Plugin hanya mengatur skin/cape; ia tidak memverifikasi kepemilikan nama,
  jadi pasang plugin autentikasi bila server Anda publik.
* Pemain dengan klien non-Nuvio tidak akan melihat tekstur dari domain situs (batasan klien Minecraft).
