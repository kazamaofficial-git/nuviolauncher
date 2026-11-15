import type { Metadata } from 'next';
import Link from 'next/link';
import type { Prisma } from '@prisma/client';
import { db } from '@/lib/db';
import { formatDate } from '@/lib/format';
import { LicenseGenerator } from '@/components/admin/LicenseGenerator';

export const metadata: Metadata = { title: 'Lisensi' };

type SearchParams = Promise<{ q?: string; status?: string }>;

export default async function LicensesPage({ searchParams }: { searchParams: SearchParams }) {
  const { q = '', status = '' } = await searchParams;
  const now = new Date();

  const where: Prisma.LicenseWhereInput = {
    ...(q
      ? {
          OR: [
            { key: { contains: q.toUpperCase() } },
            { note: { contains: q } },
            { email: { contains: q } },
          ],
        }
      : {}),
    ...(status === 'REVOKED' ? { status: 'REVOKED' } : {}),
    ...(status === 'EXPIRED' ? { expiresAt: { lt: now } } : {}),
    ...(status === 'ACTIVE'
      ? { status: 'ACTIVE', OR: [{ expiresAt: null }, { expiresAt: { gt: now } }] }
      : {}),
  };

  const licenses = await db.license.findMany({
    where,
    orderBy: { createdAt: 'desc' },
    take: 200,
    include: { _count: { select: { activations: true } } },
  });

  return (
    <>
      <header className="page-head">
        <h1>Lisensi</h1>
        <p className="muted">Buat, cari, dan kelola kunci Nuvio Plus.</p>
      </header>

      <LicenseGenerator />

      <section className="panel glass">
        <form className="toolbar" method="get">
          <input className="input" name="q" defaultValue={q} placeholder="Cari kunci, catatan, atau email…" />
          <select className="input" name="status" defaultValue={status}>
            <option value="">Semua status</option>
            <option value="ACTIVE">Aktif</option>
            <option value="REVOKED">Dicabut</option>
            <option value="EXPIRED">Kedaluwarsa</option>
          </select>
          <button className="btn btn-sm" type="submit">Filter</button>
        </form>

        <div className="table-wrap">
          <table className="table">
            <thead>
              <tr>
                <th>Kunci</th>
                <th>Status</th>
                <th>Perangkat</th>
                <th>Berlaku hingga</th>
                <th>Catatan</th>
                <th>Dibuat</th>
              </tr>
            </thead>
            <tbody>
              {licenses.length === 0 && (
                <tr><td colSpan={6} className="muted">Belum ada lisensi.</td></tr>
              )}
              {licenses.map((l) => {
                const expired = l.expiresAt !== null && l.expiresAt < now;
                const state = l.status === 'REVOKED' ? 'Dicabut' : expired ? 'Kedaluwarsa' : 'Aktif';
                const tone = state === 'Aktif' ? 'chip-ok' : 'chip-bad';
                return (
                  <tr key={l.id}>
                    <td><Link href={`/admin/licenses/${l.id}`} className="mono">{l.key}</Link></td>
                    <td><span className={`chip ${tone}`}>{state}</span></td>
                    <td>{l._count.activations} / {l.maxDevices}</td>
                    <td>{l.expiresAt ? formatDate(l.expiresAt) : 'Seumur hidup'}</td>
                    <td className="muted">{l.note || '—'}</td>
                    <td className="muted">{formatDate(l.createdAt)}</td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </section>
    </>
  );
}
