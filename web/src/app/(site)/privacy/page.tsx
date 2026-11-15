import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Kebijakan Privasi',
  alternates: { canonical: '/privacy' },
};

export default function PrivacyPage() {
  return (
    <div className="container narrow page prose">
      <h1>Kebijakan Privasi</h1>
      <p className="muted">Terakhir diperbarui: 12 November 2026</p>
      <h2>Data yang kami simpan</h2>
      <ul>
        <li><strong>Lisensi:</strong> kunci lisensi, ID perangkat acak, nama perangkat, platform, dan versi aplikasi saat Anda mengaktifkan Nuvio Plus.</li>
        <li><strong>Ulasan:</strong> nama, penilaian, dan komentar yang Anda kirim, plus hash IP yang tidak dapat dibalik untuk mencegah spam.</li>
        <li><strong>Akun Nuvio:</strong> email, username, hash kata sandi (bcrypt), ID Google bila Anda masuk dengan Google, skin/cape yang Anda unggah, dan sesi launcher. Kode OTP disimpan hanya dalam bentuk hash dan kedaluwarsa dalam 10 menit.</li>
        <li><strong>Unduhan:</strong> jumlah unduhan per platform dan versi, tanpa identitas pengunjung.</li>
      </ul>
      <h2>Yang tidak kami lakukan</h2>
      <p>Kami tidak menjual data, tidak memasang iklan, dan tidak menyimpan kata sandi Microsoft Anda. Login Microsoft berlangsung langsung antara launcher dan Microsoft/Xbox/Mojang; token disimpan terenkripsi di perangkat Anda.</p>
      <h2>Kontak</h2>
      <p>Pertanyaan tentang privasi dapat disampaikan ke Kazama Tech melalui kanal resmi yang tercantum di situs ini.</p>
    </div>
  );
}
