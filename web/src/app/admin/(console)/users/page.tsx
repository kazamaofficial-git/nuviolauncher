import type { Metadata } from 'next';
import { PlayerName } from '@/components/NuvioBadge';
import { displayName } from '@/lib/account';
import { db } from '@/lib/db';
import { formatDate } from '@/lib/format';

export const metadata: Metadata = { title: 'Pengguna' };

export default async function UsersPage() {
  const [total, users] = await Promise.all([
    db.user.count({ where: { emailVerified: true } }),
    db.user.findMany({ where: { emailVerified: true }, orderBy: { createdAt: 'desc' }, take: 200 }),
  ]);
  return (
    <>
      <header className="page-head">
        <h1>Pengguna</h1>
        <p className="muted">{total} akun Nuvio terverifikasi.</p>
      </header>
      <section className="panel glass">
        {users.length === 0 && <p className="muted">Belum ada pengguna.</p>}
        <ul className="list">
          {users.map((u) => (
            <li key={u.id} className="list-item">
              <div>
                <strong><PlayerName name={displayName(u)} badge={u.badge} /></strong>{' '}
                {u.googleId && <span className="chip chip-info">Google</span>}{' '}
                {u.skinHash && <span className="chip">Skin</span>}{' '}
                {u.capeHash && <span className="chip">Cape</span>}
                <p className="muted small">{u.email} · daftar {formatDate(u.createdAt, true)}</p>
              </div>
            </li>
          ))}
        </ul>
      </section>
    </>
  );
}
