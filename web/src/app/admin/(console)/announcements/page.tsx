import type { Metadata } from 'next';
import { db } from '@/lib/db';
import { formatDate } from '@/lib/format';
import { AnnouncementForm } from '@/components/admin/AnnouncementForm';
import { deleteAnnouncementAction, toggleAnnouncementAction } from '../../actions';

export const metadata: Metadata = { title: 'Pengumuman' };

export default async function AnnouncementsPage() {
  const items = await db.announcement.findMany({ orderBy: { createdAt: 'desc' }, take: 100 });
  return (
    <>
      <header className="page-head">
        <h1>Pengumuman</h1>
        <p className="muted">Tampil di layar Home aplikasi (maks. 10 terbaru yang aktif).</p>
      </header>

      <AnnouncementForm />

      <section className="panel glass">
        <h2>Daftar</h2>
        {items.length === 0 && <p className="muted">Belum ada pengumuman.</p>}
        <ul className="list">
          {items.map((a) => (
            <li key={a.id} className="list-item">
              <div>
                <strong>{a.title}</strong>{' '}
                <span className={`chip chip-${a.level === 'warning' ? 'warn' : a.level === 'success' ? 'ok' : 'info'}`}>{a.level}</span>{' '}
                {!a.active && <span className="chip">nonaktif</span>}
                <p className="muted">{a.body}</p>
                <span className="muted small">{formatDate(a.createdAt, true)}</span>
              </div>
              <div className="row">
                <form action={toggleAnnouncementAction}>
                  <input type="hidden" name="id" value={a.id} />
                  <button className="btn btn-ghost btn-sm" type="submit">{a.active ? 'Nonaktifkan' : 'Aktifkan'}</button>
                </form>
                <form action={deleteAnnouncementAction}>
                  <input type="hidden" name="id" value={a.id} />
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
