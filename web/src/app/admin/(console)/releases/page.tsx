import type { Metadata } from 'next';
import { db } from '@/lib/db';
import { formatBytes, formatDate, formatNumber } from '@/lib/format';
import { getReleases } from '@/lib/github';

export const metadata: Metadata = { title: 'Rilis' };

export default async function ReleasesPage() {
  const [releases, counts] = await Promise.all([
    getReleases(20),
    db.downloadEvent.groupBy({ by: ['version', 'platform'], _count: { _all: true } }),
  ]);
  const count = (version: string, platform: string) =>
    counts.find((c) => c.version === version && c.platform === platform)?._count._all ?? 0;

  return (
    <>
      <header className="page-head">
        <h1>Rilis</h1>
        <p className="muted">
          Dibaca dari GitHub Releases (cache 5 menit). Rilis baru dibuat otomatis oleh workflow build.
        </p>
      </header>

      <section className="panel glass">
        {releases.length === 0 && (
          <p className="muted">Belum ada rilis, atau GITHUB_REPO / GITHUB_TOKEN belum diatur.</p>
        )}
        <div className="table-wrap">
          <table className="table">
            <thead>
              <tr><th>Versi</th><th>Tanggal</th><th>Windows</th><th>Android</th></tr>
            </thead>
            <tbody>
              {releases.map((r) => (
                <tr key={r.tag}>
                  <td>
                    <strong>v{r.version}</strong>{' '}
                    {r.prerelease && <span className="chip chip-warn">BETA</span>}
                  </td>
                  <td className="muted">{formatDate(r.publishedAt)}</td>
                  {(['windows', 'android'] as const).map((p) => (
                    <td key={p}>
                      {r.assets[p] ? (
                        <>
                          {formatBytes(r.assets[p]!.size)}{' '}
                          <span className="muted">· {formatNumber(count(r.version, p))} unduhan</span>
                        </>
                      ) : (
                        <span className="muted">—</span>
                      )}
                    </td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>
    </>
  );
}
