import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Syarat Penggunaan',
  alternates: { canonical: '/terms' },
};

export default function TermsPage() {
  return (
    <div className="container narrow page prose">
      <h1>Syarat Penggunaan</h1>
      <p className="muted">Terakhir diperbarui: 12 November 2026</p>
      <ul>
        <li>Nuvio Launcher disediakan “apa adanya” dan masih berstatus beta; fitur dapat berubah.</li>
        <li>Nuvio tidak menyertakan Minecraft. Anda memerlukan salinan resmi untuk bermain online.</li>
        <li>Nuvio bukan produk resmi Mojang Studios atau Microsoft. Minecraft adalah merek dagang Mojang Studios.</li>
        <li>Akun Nuvio: Anda bertanggung jawab atas skin/cape yang diunggah; konten yang melanggar hukum atau menyinggung dapat dihapus dan akun dapat dinonaktifkan. Skin kustom Nuvio terlihat di server hanya bila server memakai plugin NuvioSkins.</li>
        <li>Kunci Nuvio Plus bersifat pribadi. Berbagi kunci di luar batas perangkat dapat menyebabkan pencabutan lisensi.</li>
        <li>Kazama Tech berhak menonaktifkan lisensi yang disalahgunakan.</li>
      </ul>
    </div>
  );
}
