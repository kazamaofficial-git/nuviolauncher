import { NextResponse } from 'next/server';
import { randomBytes } from 'node:crypto';
import { safeNext } from '@/lib/account';
import { env } from '@/lib/env';
import { GOOGLE_STATE_COOKIE } from '@/lib/user-session';

export const dynamic = 'force-dynamic';

/** Starts the Google OAuth authorization-code flow. */
export async function GET(req: Request) {
  const clientId = env.googleClientId();
  if (!clientId) return NextResponse.redirect(`${env.siteUrl()}/account/login?error=google`);

  const next = safeNext(new URL(req.url).searchParams.get('next'));
  const state = randomBytes(16).toString('hex');
  const url = new URL('https://accounts.google.com/o/oauth2/v2/auth');
  url.search = new URLSearchParams({
    client_id: clientId,
    redirect_uri: `${env.siteUrl()}/api/auth/google/callback`,
    response_type: 'code',
    scope: 'openid email profile',
    state,
    prompt: 'select_account',
  }).toString();

  const res = NextResponse.redirect(url);
  // state + where to go afterwards, in one short-lived httpOnly cookie
  res.cookies.set(GOOGLE_STATE_COOKIE, `${state}|${next}`, {
    httpOnly: true,
    sameSite: 'lax',
    secure: process.env.NODE_ENV === 'production',
    path: '/',
    maxAge: 600,
  });
  return res;
}
