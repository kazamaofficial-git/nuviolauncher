import type { Metadata } from 'next';
import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import { CompleteGoogleForm } from '@/components/account/AuthForms';
import { safeNext } from '@/lib/account';
import { GOOGLE_SIGNUP_COOKIE, verifyGoogleSignup } from '@/lib/user-session';

export const metadata: Metadata = { title: 'Lengkapi akun', robots: { index: false } };

export default async function CompletePage({ searchParams }: { searchParams: Promise<{ next?: string }> }) {
  const signup = await verifyGoogleSignup((await cookies()).get(GOOGLE_SIGNUP_COOKIE)?.value);
  if (!signup) redirect('/account/login');
  return (
    <section className="container auth-wrap">
      <div className="auth-card glass">
        <h1>Pilih username</h1>
        <CompleteGoogleForm next={safeNext((await searchParams).next)} email={signup.email} />
      </div>
    </section>
  );
}
