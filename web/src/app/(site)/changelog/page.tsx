import type { Metadata } from 'next';
import { formatDate } from '@/lib/format';
import { getReleases } from '@/lib/github';

export const metadata: Metadata = {
  title: 'Catatan Rilis',
  description: 'Riwayat perubahan Nuvio Launcher dari versi ke versi.',
  alternates: { canonical: '/changelog' },
};

export const dynamic = 'force-dynamic';

export default async function ChangelogPage() {
  const releases = await getReleases(15);
  return (
    <div className="container narrow page">
      <header className="section-head">
        <h1>Catatan Rilis</h1>
        <p className="muted">Apa yang baru di setiap versi Nuvio Launcher.</p>
      </header>
      {releases.length === 0 && <p className="muted center">Belum ada rilis.</p>}
      {releases.map((r) => (
        <article key={r.tag} className="panel glass">
          <h2>
            v{r.version} {r.prerelease && <span className="chip chip-warn">BETA</span>}
          </h2>
          <p className="muted small">{formatDate(r.publishedAt)}</p>
          {r.notes ? <pre className="notes">{r.notes}</pre> : <p className="muted">Tanpa catatan.</p>}
        </article>
      ))}
    </div>
  );
}
