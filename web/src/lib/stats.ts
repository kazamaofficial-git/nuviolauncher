import { db } from './db';

export interface SiteStats {
  downloads: number;
  downloadsByPlatform: Record<string, number>;
  users: number;
  reviews: number;
  rating: number;
}

const empty: SiteStats = { downloads: 0, downloadsByPlatform: {}, users: 0, reviews: 0, rating: 0 };

/** Live numbers straight from the database. Nothing is estimated or padded. */
export async function getSiteStats(): Promise<SiteStats> {
  try {
    const [byPlatform, users, dist] = await Promise.all([
      db.downloadEvent.groupBy({ by: ['platform'], _count: { _all: true } }),
      db.user.count({ where: { emailVerified: true } }),
      db.review.groupBy({ by: ['rating'], where: { status: 'APPROVED' }, _count: { _all: true } }),
    ]);
    const downloadsByPlatform = Object.fromEntries(byPlatform.map((p) => [p.platform, p._count._all]));
    const reviews = dist.reduce((s, d) => s + d._count._all, 0);
    const rating = reviews === 0 ? 0 : dist.reduce((s, d) => s + d.rating * d._count._all, 0) / reviews;
    return {
      downloads: byPlatform.reduce((s, p) => s + p._count._all, 0),
      downloadsByPlatform,
      users,
      reviews,
      rating,
    };
  } catch {
    return empty;
  }
}
