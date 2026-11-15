import type { Metadata } from 'next';
import { db } from '@/lib/db';
import { formatDate } from '@/lib/format';
import { deleteReviewAction, setReviewStatusAction } from '../../actions';

export const metadata: Metadata = { title: 'Ulasan' };

const statusLabel: Record<string, string> = {
  PENDING: 'Menunggu',
  APPROVED: 'Tampil',
  HIDDEN: 'Disembunyikan',
};

export default async function ReviewsPage() {
  const reviews = await db.review.findMany({ orderBy: { createdAt: 'desc' }, take: 200 });
  return (
    <>
      <header className="page-head">
        <h1>Ulasan</h1>
        <p className="muted">Ulasan baru tidak tampil di situs sampai Anda menyetujuinya.</p>
      </header>

      <section className="panel glass">
        {reviews.length === 0 && <p className="muted">Belum ada ulasan.</p>}
        <ul className="list">
          {reviews.map((r) => (
            <li key={r.id} className="list-item">
              <div>
                <strong>{r.name}</strong>{' '}
                <span className="stars" aria-label={`${r.rating} dari 5`}>{'★'.repeat(r.rating)}{'☆'.repeat(5 - r.rating)}</span>{' '}
                <span className={`chip ${r.status === 'APPROVED' ? 'chip-ok' : r.status === 'HIDDEN' ? 'chip-bad' : 'chip-warn'}`}>
                  {statusLabel[r.status] ?? r.status}
                </span>
                <p>{r.comment}</p>
                <span className="muted small">{r.platform || '—'} · {formatDate(r.createdAt, true)}</span>
              </div>
              <div className="row">
                {r.status !== 'APPROVED' && (
                  <form action={setReviewStatusAction}>
                    <input type="hidden" name="id" value={r.id} />
                    <input type="hidden" name="status" value="APPROVED" />
                    <button className="btn btn-sm" type="submit">Setujui</button>
                  </form>
                )}
                {r.status !== 'HIDDEN' && (
                  <form action={setReviewStatusAction}>
                    <input type="hidden" name="id" value={r.id} />
                    <input type="hidden" name="status" value="HIDDEN" />
                    <button className="btn btn-ghost btn-sm" type="submit">Sembunyikan</button>
                  </form>
                )}
                <form action={deleteReviewAction}>
                  <input type="hidden" name="id" value={r.id} />
                  <button className="btn btn-danger btn-sm" type="submit">Hapus</button>
                </form>
              </div>
            </li>
          ))}
        </ul>
      </section>
    </>
  );
}
