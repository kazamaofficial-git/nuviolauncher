import type { Metadata } from 'next';
import { redirect } from 'next/navigation';
import { VerifyForm } from '@/components/account/AuthForms';
import { safeNext } from '@/lib/account';

export const metadata: Metadata = { title: 'Verifikasi email', robots: { index: false } };

export default async function VerifyPage({ searchParams }: { searchParams: Promise<{ email?: string; next?: string }> }) {
  const sp = await searchParams;
  if (!sp.email) redirect('/account/register');
  return (
    <section className="container auth-wrap">
      <div className="auth-card glass">
        <h1>Masukkan kode OTP</h1>
        <p className="muted">Kami mengirim kode 6 digit ke <strong>{sp.email}</strong>. Berlaku 10 menit.</p>
        <VerifyForm email={sp.email} next={safeNext(sp.next)} />
      </div>
    </section>
  );
}
