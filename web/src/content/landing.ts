/** Editable copy for the landing page. Keep claims in sync with what the app really does. */

export type FeatureStatus = 'ready' | 'beta' | 'soon';

export interface Feature {
  icon: 'bolt' | 'box' | 'key' | 'orbit' | 'puzzle' | 'user' | 'server' | 'phone';
  title: string;
  body: string;
  tag: string;
  status: FeatureStatus;
}

export const features: Feature[] = [
  {
    icon: 'bolt',
    title: 'Unduhan Paralel',
    body: 'Aset, library, dan client Minecraft diunduh bersamaan dengan verifikasi SHA-1. 4 thread untuk Free, 16 thread untuk Plus.',
    tag: '4 / 16 thread',
    status: 'ready',
  },
  {
    icon: 'box',
    title: 'Instance Terisolasi',
    body: 'Setiap instance punya folder sendiri dengan versi, RAM, dan argumen JVM terpisah, jadi dunia dan konfigurasi tidak saling bentrok.',
    tag: 'Sandbox per profil',
    status: 'ready',
  },
  {
    icon: 'key',
    title: 'Satu Lisensi, Dua Platform',
    body: 'Satu kunci Nuvio Plus berlaku untuk Windows dan Android, dengan batas perangkat yang bisa Anda kelola sendiri.',
    tag: 'PC + Android',
    status: 'ready',
  },
  {
    icon: 'orbit',
    title: 'Desain Neon Landscape',
    body: 'Antarmuka ungu neon bernuansa galaksi yang dirancang landscape penuh, nyaman di monitor maupun layar ponsel.',
    tag: 'Futuristik',
    status: 'ready',
  },
  {
    icon: 'phone',
    title: 'Peluncuran di Android',
    body: 'Versi Android saat ini mencakup antarmuka, daftar versi, instance, dan lisensi. Menjalankan game langsung di Android sedang dikembangkan.',
    tag: 'Dalam pengembangan',
    status: 'beta',
  },
  {
    icon: 'puzzle',
    title: 'Mod Loader & Modpack',
    body: 'Dukungan Fabric, Forge, NeoForge, Quilt, dan penjelajah modpack dari Modrinth akan hadir di rilis berikutnya.',
    tag: 'Segera',
    status: 'soon',
  },
  {
    icon: 'user',
    title: 'Microsoft, Nuvio & Akun Lokal',
    body: 'Masuk dengan Microsoft (butuh persetujuan Mojang untuk client id), akun Nuvio dengan skin & cape kustom, atau akun lokal. Multi-akun dan token disimpan aman di perangkat.',
    tag: 'Beta',
    status: 'beta',
  },
  {
    icon: 'box',
    title: 'Pusat Konten',
    body: 'Cari dan pasang mod, shader, resource pack, dan dunia dari Modrinth dan CurseForge langsung ke instance Anda.',
    tag: 'Beta',
    status: 'beta',
  },
  {
    icon: 'server',
    title: 'Host Server LAN',
    body: 'Buka server lokal untuk bermain bersama teman dalam satu jaringan. Fitur ini akan menjadi bagian dari Nuvio Plus.',
    tag: 'Segera · Plus',
    status: 'soon',
  },
];

export interface SpecGroup {
  platform: 'windows' | 'android';
  title: string;
  subtitle: string;
  rows: { label: string; value: string; highlight?: boolean }[];
}

export const specs: SpecGroup[] = [
  {
    platform: 'windows',
    title: 'Nuvio untuk Windows',
    subtitle: 'Arsitektur: x64 (64-bit)',
    rows: [
      { label: 'Sistem operasi', value: 'Windows 10 / 11 (64-bit)' },
      { label: 'RAM minimum', value: '4 GB (8 GB direkomendasikan)' },
      { label: 'Java', value: 'Java 17 / 21 terpasang, terdeteksi otomatis', highlight: true },
      { label: 'Grafis', value: 'GPU dengan OpenGL 3.2+' },
      { label: 'Penyimpanan', value: '300 MB + ruang untuk game' },
    ],
  },
  {
    platform: 'android',
    title: 'Nuvio untuk Android',
    subtitle: 'Format: satu APK universal',
    rows: [
      { label: 'Versi Android', value: 'Android 7.0 ke atas' },
      { label: 'RAM minimum', value: '3 GB (4 GB atau lebih optimal)' },
      { label: 'Arsitektur CPU', value: 'arm64-v8a, armeabi-v7a, x86_64 (satu berkas)', highlight: true },
      { label: 'Status', value: 'Beta: peluncuran game dalam pengembangan' },
      { label: 'Penyimpanan', value: '150 MB (paket APK)' },
    ],
  },
];

export interface CompareRow {
  label: string;
  free: string;
  plus: string;
}

export const compareRows: CompareRow[] = [
  { label: 'Thread unduhan paralel', free: '4 thread', plus: '16 thread' },
  { label: 'Jumlah instance', free: 'Maksimal 3', plus: 'Tanpa batas' },
  { label: 'Warna aksen kustom', free: 'Terkunci', plus: 'Terbuka' },
  { label: 'Profil JVM per instance', free: 'Terkunci', plus: 'Terbuka' },
  { label: 'Satu lisensi untuk PC & Android', free: '—', plus: 'Ya' },
  { label: 'Host server LAN', free: '—', plus: 'Segera' },
];

export interface FaqItem {
  q: string;
  a: string;
}

export const faqs: FaqItem[] = [
  {
    q: 'Apa itu Nuvio Launcher?',
    a: 'Nuvio Launcher adalah launcher Minecraft Java Edition buatan Kazama Tech dengan antarmuka neon futuristik. Aplikasi ini mengelola versi, instance, dan mengunduh semua berkas game secara paralel.',
  },
  {
    q: 'Apakah Nuvio gratis?',
    a: 'Ya. Versi Free sudah mencakup fitur inti dengan batas 3 instance dan 4 thread unduhan. Nuvio Plus membuka instance tanpa batas, 16 thread unduhan, warna aksen kustom, dan profil JVM per instance.',
  },
  {
    q: 'Apakah sudah bisa dimainkan di Android?',
    a: 'Belum sepenuhnya. Versi Android beta saat ini berisi antarmuka, daftar versi, instance, dan lisensi. Menjalankan Minecraft langsung di Android masih dalam pengembangan. Di Windows, peluncuran Minecraft Java sudah berfungsi.',
  },
  {
    q: 'Mengapa tidak ada versi 32-bit?',
    a: 'Nuvio hanya dirilis sebagai satu penginstal Windows 64-bit. Minecraft modern memerlukan Java 64-bit, dan Windows 32-bit sudah jarang digunakan. Untuk Android, satu APK universal sudah mencakup perangkat 32-bit (armeabi-v7a) dan 64-bit.',
  },
  {
    q: 'Bagaimana cara mengaktifkan lisensi Plus?',
    a: 'Buka menu Plus di aplikasi, tempel kunci berformat NUVIO-XXXX-XXXX-XXXX, lalu tekan Aktifkan. Satu kunci bisa dipakai di beberapa perangkat sesuai batasnya, dan Anda bisa melepas perangkat kapan saja dari aplikasi.',
  },
  {
    q: 'Akun apa saja yang didukung?',
    a: 'Tiga jenis: Microsoft (untuk bermain online di server mana pun), akun Nuvio (skin & cape kustom yang juga bisa diatur di situs ini), dan akun lokal (offline). Nuvio tidak menyertakan Minecraft, jadi akun Microsoft harus memiliki Java Edition.',
  },
  {
    q: 'Di mana skin & cape Nuvio terlihat?',
    a: 'Di diri sendiri, di dunia singleplayer/LAN, dan bagi pemain Nuvio lain. Agar terlihat di server, server memakai plugin NuvioSkins buatan Kazama Tech (gratis, tersedia di halaman unduhan rilis). Server publik resmi Mojang tidak dapat menampilkannya.',
  },
  {
    q: 'Windows menampilkan peringatan SmartScreen. Apakah aman?',
    a: 'Selama masa beta, penginstal belum memiliki sertifikat penandatanganan kode berbayar sehingga Windows dapat menampilkan peringatan "aplikasi tidak dikenal". Unduh hanya dari situs resmi ini, lalu pilih "Informasi lebih lanjut" → "Tetap jalankan".',
  },
];
