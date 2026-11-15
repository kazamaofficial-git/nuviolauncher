import { db } from '@/lib/db';
import { formatDate, formatNumber } from '@/lib/format';
import { getLatestRelease } from '@/lib/github';
import { StatCard } from '@/components/admin/StatCard';

export default async function DashboardPage() {
  const weekAgo = new Date(Date.now() - 7 * 86_400_000);
  const now = new Date();

  const [licenses, active, activations, pending, downloads, downloads7d, byPlatform, release] =
    await Promise.all([
      db.license.count(),
      db.license.count({
        where: { status: 'ACTIVE', OR: [{ expiresAt: null }, { expiresAt: { gt: now } }] },
      }),
      db.activation.count(),
      db.review.count({ where: { status: 'PENDING' } }),
      db.downloadEvent.count(),
      db.downloadEvent.count({ where: { createdAt: { gte: weekAgo } } }),
      db.downloadEvent.groupBy({ by: ['platform'], _count: { _all: true } }),
      getLatestRelease(),
    ]);

  const platformCount = (p: string) => byPlatform.find((r) => r.platform === p)?._count._all ?? 0;

  return (
    <>
      <header className="page-head">
        <h1>Dashboard</h1>
        <p className="muted">Ringkasan Nuvio Launcher.</p>
      </header>

      <section className="stat-grid">
        <StatCard label="Total unduhan" value={formatNumber(downloads)} hint={`${formatNumber(downloads7d)} dalam 7 hari`} />
        <StatCard label="Unduhan Windows" value={formatNumber(platformCount('windows'))} />
        <StatCard label="Unduhan Android" value={formatNumber(platformCount('android'))} />
        <StatCard label="Lisensi aktif" value={formatNumber(active)} hint={`dari ${formatNumber(licenses)} total`} />
        <StatCard label="Perangkat aktif" value={formatNumber(activations)} />
        <StatCard label="Ulasan menunggu" value={formatNumber(pending)} href="/admin/reviews" />
      </section>

      <section className="panel glass">
        <h2>Rilis terbaru</h2>
        {release ? (
          <p>
            <strong>v{release.version}</strong>{' '}
            {release.prerelease && <span className="chip chip-warn">BETA</span>}{' '}
            <span className="muted">· {formatDate(release.publishedAt)}</span>
          </p>
        ) : (
          <p className="muted">
            Belum ada rilis atau GitHub belum dikonfigurasi (cek GITHUB_REPO dan GITHUB_TOKEN).
          </p>
        )}
      </section>
    </>
  );
}
