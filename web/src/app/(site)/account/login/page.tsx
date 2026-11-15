import type { Metadata } from 'next';
import { redirect } from 'next/navigation';
import { AccountLoginForm } from '@/components/account/AuthForms';
import { safeNext } from '@/lib/account';
import { env } from '@/lib/env';
import { getCurrentUser } from '@/lib/user-auth';

export const metadata: Metadata = { title: 'Masuk', robots: { index: false } };

const errors: Record<string, string> = {
  google: 'Masuk dengan Google gagal. Coba lagi.',
  google_email: 'Email Google Anda belum terverifikasi.',
};

export default async function LoginPage({ searchParams }: { searchParams: Promise<{ next?: string; error?: string }> }) {
  const sp = await searchParams;
  const next = safeNext(sp.next);
  if (await getCurrentUser()) redirect(next);
  const google = Boolean(env.googleClientId());
  return (
    <section className="container auth-wrap">
      <div className="auth-card glass">
        <h1>Masuk ke Nuvio</h1>
        <p className="muted">Gunakan akun Nuvio untuk mengelola skin &amp; cape dan masuk ke launcher.</p>
        {sp.error && errors[sp.error] && <p className="form-error" role="alert">{errors[sp.error]}</p>}
        <AccountLoginForm next={next} />
        {google && (
          <a className="btn btn-ghost btn-block" href={`/api/auth/google/start?next=${encodeURIComponent(next)}`}>Lanjut dengan Google</a>
        )}
      </div>
    </section>
  );
}
