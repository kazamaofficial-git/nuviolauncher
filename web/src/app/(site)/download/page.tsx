import type { Metadata } from 'next';
import { DownloadCards } from '@/components/DownloadCards';
import { formatDate } from '@/lib/format';
import { getLatestRelease } from '@/lib/github';

export const metadata: Metadata = {
  title: 'Unduh Nuvio Launcher',
  description:
    'Unduh Nuvio Launcher untuk Windows 10/11 (64-bit) dan Android (APK universal). Versi beta terbaru dari Kazama Tech.',
  alternates: { canonical: '/download' },
};

export const dynamic = 'force-dynamic';

export default async function DownloadPage() {
  const release = await getLatestRelease();
  return (
    <div className="container narrow page">
      <header className="section-head">
        <h1>Unduh Nuvio Launcher</h1>
        <p className="muted">
          {release
            ? `Versi terbaru v${release.version}${release.prerelease ? ' (beta)' : ''} · dirilis ${formatDate(release.publishedAt)}`
            : 'Build pertama belum dirilis. Kembali lagi sebentar lagi.'}
        </p>
      </header>

      <DownloadCards release={release} />

      <section className="panel glass">
        <h2>Cara memasang</h2>
        <div className="steps">
          <div>
            <h3>Windows</h3>
            <ol>
              <li>Unduh penginstal, lalu jalankan.</li>
              <li>Jika muncul peringatan SmartScreen, pilih “Informasi lebih lanjut” → “Tetap jalankan” (selama beta penginstal belum bertanda tangan kode).</li>
              <li>Pastikan Java 17 atau 21 (64-bit) terpasang. Nuvio akan mendeteksinya.</li>
            </ol>
          </div>
          <div>
            <h3>Android</h3>
            <ol>
              <li>Unduh berkas APK, lalu buka dari notifikasi atau aplikasi File.</li>
              <li>Izinkan “Pasang dari sumber ini” untuk browser Anda bila diminta.</li>
              <li>Satu APK universal bekerja di perangkat 32-bit maupun 64-bit.</li>
            </ol>
          </div>
        </div>
      </section>

      {release?.notes && (
        <section className="panel glass">
          <h2>Catatan rilis v{release.version}</h2>
          <pre className="notes">{release.notes}</pre>
        </section>
      )}
    </div>
  );
}
