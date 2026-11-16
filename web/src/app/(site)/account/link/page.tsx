import type { Metadata } from 'next';
import Link from 'next/link';
import { PlayerName } from '@/components/NuvioBadge';
import { LinkRedirect } from '@/components/account/LinkRedirect';
import { approveLinkAction, denyLinkAction } from '../actions';
import { db } from '@/lib/db';
import { displayName } from '@/lib/account';
import { requireUser } from '@/lib/user-auth';

export const metadata: Metadata = { title: 'Hubungkan launcher', robots: { index: false } };

export default async function LinkPage({ searchParams }: { searchParams: Promise<{ code?: string; state?: string }> }) {
  const { code = '', state } = await searchParams;
  const user = await requireUser(`/account/link?code=${encodeURIComponent(code)}${state ? `&state=${state}` : ''}`);

  if (state === 'done') {
    return (
      <section className="container auth-wrap">
        <div className="auth-card glass center-text">
          <h1>Berhasil terhubung</h1>
          <p className="muted">Kembali ke Nuvio Launcher — akun Anda sudah masuk. Jendela ini boleh ditutup.</p>
          <LinkRedirect />
          <Link href="/account" className="btn btn-ghost">Buka akun</Link>
        </div>
      </section>
    );
  }

  const link = code
    ? await db.deviceLink.findFirst({ where: { userCode: code.toUpperCase(), status: 'PENDING', expiresAt: { gt: new Date() } } })
    : null;

  if (!link || state === 'invalid') {
    return (
      <section className="container auth-wrap">
        <div className="auth-card glass center-text">
          <h1>Kode tidak berlaku</h1>
          <p className="muted">Kode sudah kedaluwarsa atau dipakai. Mulai ulang proses masuk dari launcher.</p>
        </div>
      </section>
    );
  }

  return (
    <section className="container auth-wrap">
      <div className="auth-card glass center-text">
        <h1>Hubungkan launcher?</h1>
        <p className="muted">Nuvio Launcher meminta akses ke akun <strong><PlayerName name={displayName(user)} badge={user.badge} /></strong>.</p>
        <p className="otp-show">{link.userCode}</p>
        <p className="muted small">Pastikan kode ini sama dengan yang tampil di launcher.</p>
        <form action={approveLinkAction} className="stack">
          <input type="hidden" name="code" value={link.userCode} />
          <button className="btn btn-block" type="submit">Izinkan</button>
        </form>
        <form action={denyLinkAction}>
          <input type="hidden" name="code" value={link.userCode} />
          <button className="btn btn-ghost btn-block" type="submit">Tolak</button>
        </form>
      </div>
    </section>
  );
}
