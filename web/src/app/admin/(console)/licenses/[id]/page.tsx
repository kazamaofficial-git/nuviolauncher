import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { db } from '@/lib/db';
import { formatDate } from '@/lib/format';
import {
  deleteLicenseAction,
  removeActivationAction,
  setLicenseStatusAction,
  updateLicenseAction,
} from '../../../actions';

export const metadata: Metadata = { title: 'Detail lisensi' };

export default async function LicenseDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const license = await db.license.findUnique({
    where: { id },
    include: { activations: { orderBy: { lastSeenAt: 'desc' } } },
  });
  if (!license) notFound();

  const revoked = license.status === 'REVOKED';
  const expiresValue = license.expiresAt ? license.expiresAt.toISOString().slice(0, 10) : '';

  return (
    <>
      <header className="page-head">
        <p><Link href="/admin/licenses" className="muted">← Semua lisensi</Link></p>
        <h1 className="mono">{license.key}</h1>
        <p>
          <span className={`chip ${revoked ? 'chip-bad' : 'chip-ok'}`}>{revoked ? 'Dicabut' : 'Aktif'}</span>{' '}
          <span className="muted">Dibuat {formatDate(license.createdAt)}</span>
        </p>
      </header>

      <section className="panel glass">
        <h2>Pengaturan</h2>
        <form action={updateLicenseAction} className="form-grid">
          <input type="hidden" name="id" value={license.id} />
          <label>Maks. perangkat
            <input className="input" type="number" name="maxDevices" min={1} max={20} defaultValue={license.maxDevices} />
          </label>
          <label>Berlaku hingga (kosong = seumur hidup)
            <input className="input" type="date" name="expires" defaultValue={expiresValue} />
          </label>
          <label>Email pembeli
            <input className="input" name="email" defaultValue={license.email} maxLength={120} />
          </label>
          <label>Catatan
            <input className="input" name="note" defaultValue={license.note} maxLength={200} />
          </label>
          <div className="form-actions">
            <button className="btn" type="submit">Simpan</button>
          </div>
        </form>
      </section>

      <section className="panel glass">
        <h2>Perangkat ({license.activations.length}/{license.maxDevices})</h2>
        <div className="table-wrap">
          <table className="table">
            <thead>
              <tr><th>Perangkat</th><th>Platform</th><th>Versi</th><th>Terakhir aktif</th><th /></tr>
            </thead>
            <tbody>
              {license.activations.length === 0 && (
                <tr><td colSpan={5} className="muted">Belum ada perangkat.</td></tr>
              )}
              {license.activations.map((a) => (
                <tr key={a.id}>
                  <td>{a.deviceName || <span className="muted mono">{a.deviceId.slice(0, 8)}</span>}</td>
                  <td>{a.platform || '—'}</td>
                  <td>{a.appVersion || '—'}</td>
                  <td className="muted">{formatDate(a.lastSeenAt, true)}</td>
                  <td>
                    <form action={removeActivationAction}>
                      <input type="hidden" name="id" value={a.id} />
                      <input type="hidden" name="licenseId" value={license.id} />
                      <button className="btn btn-ghost btn-sm" type="submit">Lepas</button>
                    </form>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>

      <section className="panel glass danger-zone">
        <h2>Tindakan</h2>
        <div className="row">
          <form action={setLicenseStatusAction}>
            <input type="hidden" name="id" value={license.id} />
            <input type="hidden" name="status" value={revoked ? 'ACTIVE' : 'REVOKED'} />
            <button className="btn btn-sm" type="submit">{revoked ? 'Aktifkan kembali' : 'Cabut lisensi'}</button>
          </form>
          <form action={deleteLicenseAction}>
            <input type="hidden" name="id" value={license.id} />
            <button className="btn btn-danger btn-sm" type="submit">Hapus permanen</button>
          </form>
        </div>
        <p className="muted small">Mencabut lisensi menonaktifkan fitur Plus di semua perangkat saat validasi berikutnya.</p>
      </section>
    </>
  );
}
