import { NextResponse } from 'next/server';
import { safeNext } from '@/lib/account';
import { db } from '@/lib/db';
import { env } from '@/lib/env';
import {
  GOOGLE_SIGNUP_COOKIE,
  GOOGLE_STATE_COOKIE,
  USER_COOKIE,
  USER_TTL_SECONDS,
  signGoogleSignup,
  signUserSession,
} from '@/lib/user-session';

export const dynamic = 'force-dynamic';

interface GoogleUser {
  sub: string;
  email?: string;
  email_verified?: boolean;
}

/** Finishes Google sign-in: logs in an existing account or sends a new user to pick a username. */
export async function GET(req: Request) {
  const site = env.siteUrl();
  const secure = process.env.NODE_ENV === 'production';
  const fail = (reason: string) => NextResponse.redirect(`${site}/account/login?error=${reason}`);

  const url = new URL(req.url);
  const code = url.searchParams.get('code');
  const state = url.searchParams.get('state');
  const cookie = req.headers.get('cookie')?.split(/;\s*/).find((c) => c.startsWith(`${GOOGLE_STATE_COOKIE}=`));
  const [savedState, savedNext] = decodeURIComponent(cookie?.split('=').slice(1).join('=') ?? '').split('|');
  if (!code || !state || !savedState || state !== savedState) return fail('google');

  try {
    const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        code,
        client_id: env.googleClientId(),
        client_secret: env.googleClientSecret(),
        redirect_uri: `${site}/api/auth/google/callback`,
        grant_type: 'authorization_code',
      }),
    });
    if (!tokenRes.ok) return fail('google');
    const { access_token } = (await tokenRes.json()) as { access_token?: string };
    if (!access_token) return fail('google');

    const infoRes = await fetch('https://openidconnect.googleapis.com/v1/userinfo', {
      headers: { Authorization: `Bearer ${access_token}` },
    });
    if (!infoRes.ok) return fail('google');
    const info = (await infoRes.json()) as GoogleUser;
    if (!info.sub || !info.email || !info.email_verified) return fail('google_email');
    const email = info.email.toLowerCase();
    const next = safeNext(savedNext);

    let user = await db.user.findUnique({ where: { googleId: info.sub } });
    if (!user) {
      const byEmail = await db.user.findUnique({ where: { email } });
      if (byEmail) {
        // Same verified e-mail: link Google to the existing account.
        user = await db.user.update({ where: { id: byEmail.id }, data: { googleId: info.sub, emailVerified: true } });
      }
    }

    const res = NextResponse.redirect(`${site}${user ? next : `/account/complete?next=${encodeURIComponent(next)}`}`);
    res.cookies.delete(GOOGLE_STATE_COOKIE);
    if (user) {
      res.cookies.set(USER_COOKIE, await signUserSession(user.id), {
        httpOnly: true, sameSite: 'lax', secure, path: '/', maxAge: USER_TTL_SECONDS,
      });
    } else {
      res.cookies.set(GOOGLE_SIGNUP_COOKIE, await signGoogleSignup({ googleId: info.sub, email }), {
        httpOnly: true, sameSite: 'lax', secure, path: '/', maxAge: 900,
      });
    }
    return res;
  } catch {
    return fail('google');
  }
}

