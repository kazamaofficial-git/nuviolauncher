import { formatNumber } from '@/lib/format';
import { getSiteStats } from '@/lib/stats';

/** Real counters from the database; zero is shown as zero. */
export async function StatsStrip() {
  const s = await getSiteStats();
  const items = [
    { value: formatNumber(s.downloads), label: 'Total unduhan' },
    { value: formatNumber(s.downloadsByPlatform.windows ?? 0), label: 'Unduhan Windows' },
    { value: formatNumber(s.downloadsByPlatform.android ?? 0), label: 'Unduhan Android' },
    { value: formatNumber(s.users), label: 'Akun Nuvio' },
    { value: s.reviews > 0 ? `${s.rating.toFixed(1)} ★` : '—', label: s.reviews > 0 ? `${formatNumber(s.reviews)} ulasan` : 'Belum ada ulasan' },
  ];
  return (
    <section className="container stats-strip" aria-label="Statistik Nuvio">
      {items.map((i) => (
        <div key={i.label} className="stat glass">
          <strong>{i.value}</strong>
          <span className="muted small">{i.label}</span>
        </div>
      ))}
    </section>
  );
}
