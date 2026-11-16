# Menjalankan Minecraft Java di Android — status & rencana

Status: **belum diimplementasikan**. UI, versi, instance, lisensi, akun, konten, loader, dan modpack sudah ada;
yang belum ada adalah mesin yang benar-benar menjalankan game di Android.

## Mengapa ini bukan sekadar "panggil java"
Android tidak punya JVM desktop maupun OpenGL desktop. Launcher seperti PojavLauncher/Zalith menyertakan:

1. **JRE untuk Android** (OpenJDK 8/17/21 build aarch64/arm/x86_64) yang diekstrak ke penyimpanan aplikasi.
2. **Jembatan LWJGL/GLFW**: pustaka native (`libpojavexec.so`) + kelas Java yang menggantikan GLFW agar
   Minecraft menggambar ke `Surface` Android dan menerima sentuhan/keyboard.
3. **Penerjemah OpenGL** (gl4es / MobileGlues / ANGLE / Zink) karena Minecraft memakai OpenGL desktop.
4. **Activity native** (Kotlin/Java) yang memiliki SurfaceView, mem-fork proses JVM, dan menyediakan kontrol layar
   sentuh (layout HUD yang bisa diatur), IME, dan gamepad.

## Rencana integrasi untuk Nuvio
* Platform channel Flutter `nuvio/runtime` ↔ Kotlin: `ensureRuntime(javaMajor)`, `launch(args, gameDir)`, `stop()`, stream log.
* CI mengunduh komponen runtime yang berlisensi terbuka (JRE build, LWJGL3 bridge, renderer) dan memasukkannya ke `android/app/src/main/jniLibs`
  atau mengunduhnya saat pertama dijalankan dari rilis yang diverifikasi SHA-256.
* `AndroidGameLauncher` memakai pipeline unduhan/loader/modpack yang sama dengan `DesktopGameLauncher`
  (sudah platform-agnostic) dan hanya mengganti langkah "start process" dengan panggilan channel di atas.
* Editor layout kontrol (HUD sentuh) menjadi halaman di Settings, disimpan per profil.

Pekerjaan ini membutuhkan perangkat Android nyata untuk debugging JNI/GL dan memperhatikan lisensi
(LGPL/GPL pada komponen Pojav/Zalith). Karena itu tidak dikirim sebagai kode yang belum teruji.
