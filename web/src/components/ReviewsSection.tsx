import { db } from '@/lib/db';
import { formatNumber, timeAgo } from '@/lib/format';
import { IconStar } from './Icons';
import { ReviewForm } from './ReviewForm';

/** Real, moderated reviews only. Nothing is seeded or fabricated. */
export async function ReviewsSection() {
  const [dist, latest] = await Promise.all([
    db.review.groupBy({ by: ['rating'], where: { status: 'APPROVED' }, _count: { _all: true } }),
    db.review.findMany({ where: { status: 'APPROVED' }, orderBy: { createdAt: 'desc' }, take: 6 }),
  ]);

  const total = dist.reduce((sum, d) => sum + d._count._all, 0);
  const average = total === 0 ? 0 : dist.reduce((sum, d) => sum + d.rating * d._count._all, 0) / total;
  const countFor = (stars: number) => dist.find((d) => d.rating === stars)?._count._all ?? 0;

  return (
    <section id="ulasan" className="section container">
      <div className="section-head">
        <span className="eyebrow"><IconStar size={14} /> Ulasan Pemain</span>
        <h2>Kata komunitas</h2>
        <p className="muted">Ulasan dari pengguna Nuvio. Setiap ulasan dimoderasi sebelum ditampilkan.</p>
      </div>

      <div className="reviews-grid">
        <div className="rating-card glass">
          {total > 0 ? (
            <>
              <div className="rating-big">{average.toFixed(1)}</div>
              <div className="stars" aria-label={`Rata-rata ${average.toFixed(1)} dari 5`}>
                {'★'.repeat(Math.round(average))}{'☆'.repeat(5 - Math.round(average))}
              </div>
              <p className="muted small">Berdasarkan {formatNumber(total)} ulasan</p>
              <ul className="bars">
                {[5, 4, 3, 2, 1].map((s) => (
                  <li key={s}>
                    <span>{s} ★</span>
                    <span className="bar"><i style={{ width: `${(countFor(s) / total) * 100}%` }} /></span>
                    <span className="muted">{countFor(s)}</span>
                  </li>
                ))}
              </ul>
            </>
          ) : (
            <p className="muted">Belum ada ulasan. Jadilah yang pertama!</p>
          )}
          <ReviewForm />
        </div>

        <ul className="review-list">
          {latest.map((r) => (
            <li key={r.id} className="review glass">
              <div className="review-head">
                <span className="avatar">{r.name.charAt(0).toUpperCase()}</span>
                <div>
                  <strong>{r.name}</strong>
                  <span className="muted small"> · {timeAgo(r.createdAt)}{r.platform ? ` · ${r.platform}` : ''}</span>
                </div>
                <span className="stars" aria-label={`${r.rating} dari 5`}>{'★'.repeat(r.rating)}{'☆'.repeat(5 - r.rating)}</span>
              </div>
              <p>{r.comment}</p>
            </li>
          ))}
        </ul>
      </div>
    </section>
  );
}
