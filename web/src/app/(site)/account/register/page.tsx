import type { Metadata } from 'next';
import { redirect } from 'next/navigation';
import { RegisterForm } from '@/components/account/AuthForms';
import { safeNext } from '@/lib/account';
import { env } from '@/lib/env';
import { getCurrentUser } from '@/lib/user-auth';

export const metadata: Metadata = { title: 'Daftar', robots: { index: false } };

export default async function RegisterPage({ searchParams }: { searchParams: Promise<{ next?: string }> }) {
  const next = safeNext((await searchParams).next);
  if (await getCurrentUser()) redirect(next);
  const google = Boolean(env.googleClientId());
  return (
    <section className="container auth-wrap">
      <div className="auth-card glass">
        <h1>Buat akun Nuvio</h1>
        <p className="muted">Kode OTP dikirim ke email Anda untuk verifikasi.</p>
        <RegisterForm next={next} />
        {google && (
          <a className="btn btn-ghost btn-block" href={`/api/auth/google/start?next=${encodeURIComponent(next)}`}>Daftar dengan Google</a>
        )}
      </div>
    </section>
  );
}
