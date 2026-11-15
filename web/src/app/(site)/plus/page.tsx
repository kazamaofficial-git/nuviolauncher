import type { Metadata } from 'next';
import { compareRows } from '@/content/landing';
import { env } from '@/lib/env';

export const metadata: Metadata = {
  title: 'Nuvio Plus',
  description:
    'Nuvio Plus membuka instance tanpa batas, 16 thread unduhan, warna aksen kustom, dan profil JVM per instance. Satu kunci untuk PC dan Android.',
  alternates: { canonical: '/plus' },
};

export const dynamic = 'force-dynamic';

export default function PlusPage() {
  const purchaseUrl = env.purchaseUrl();
  return (
    <div className="container narrow page">
      <header className="section-head">
        <span className="eyebrow">Nuvio Plus</span>
        <h1>Satu kunci. PC &amp; Android.</h1>
        <p className="muted">Dukung pengembangan Nuvio dan buka fitur tambahan di semua perangkat Anda.</p>
      </header>

      <div className="compare glass">
        <table>
          <thead>
            <tr><th>Fitur</th><th>Free</th><th className="plus-col">Nuvio Plus</th></tr>
          </thead>
          <tbody>
            {compareRows.map((r) => (
              <tr key={r.label}>
                <td>{r.label}</td>
                <td className="muted">{r.free}</td>
                <td className="plus-col">{r.plus}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="center">
        {purchaseUrl ? (
          <a className="btn" href={purchaseUrl} target="_blank" rel="noopener noreferrer">Beli kunci Plus</a>
        ) : (
          <span className="btn disabled" aria-disabled="true">Pembelian segera dibuka</span>
        )}
      </div>

      <section className="panel glass">
        <h2>Cara mengaktifkan</h2>
        <ol>
          <li>Buka Nuvio Launcher, pilih menu <strong>Plus</strong>.</li>
          <li>Tempel kunci berformat <span className="mono">NUVIO-XXXX-XXXX-XXXX</span>.</li>
          <li>Tekan <strong>Aktifkan</strong>. Fitur Plus langsung terbuka.</li>
          <li>Ingin pindah perangkat? Tekan <strong>Lepas perangkat</strong> di menu yang sama.</li>
        </ol>
        <p className="muted small">Aplikasi memeriksa ulang lisensi setiap 24 jam dan tetap berfungsi hingga 7 hari saat offline.</p>
      </section>
    </div>
  );
}
