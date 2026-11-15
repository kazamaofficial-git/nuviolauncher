import { timingSafeEqual } from 'node:crypto';
import bcrypt from 'bcryptjs';
import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import { env } from './env';
import {
  SESSION_COOKIE,
  SESSION_TTL_SECONDS,
  signSession,
  verifySession,
} from './session-token';

function safeEqual(a: string, b: string): boolean {
  const ba = Buffer.from(a);
  const bb = Buffer.from(b);
  return ba.length === bb.length && timingSafeEqual(ba, bb);
}

/** Checks the credentials against ADMIN_EMAIL / ADMIN_PASSWORD_HASH. */
export async function checkCredentials(email: string, password: string): Promise<boolean> {
  const expectedEmail = env.adminEmail();
  const hash = env.adminPasswordHash();
  if (!expectedEmail || !hash) return false;

  // Always run bcrypt so response time does not reveal whether the e-mail matched.
  const passwordOk = await bcrypt.compare(password, hash);
  return safeEqual(email.trim().toLowerCase(), expectedEmail) && passwordOk;
}

export async function startSession(email: string): Promise<void> {
  const token = await signSession(email.trim().toLowerCase());
  const jar = await cookies();
  jar.set(SESSION_COOKIE, token, {
    httpOnly: true,
    sameSite: 'lax',
    secure: process.env.NODE_ENV === 'production',
    path: '/',
    maxAge: SESSION_TTL_SECONDS,
  });
}

export async function endSession(): Promise<void> {
  const jar = await cookies();
  jar.delete(SESSION_COOKIE);
}

/** Current admin e-mail or null. */
export async function getAdmin(): Promise<string | null> {
  const jar = await cookies();
  return verifySession(jar.get(SESSION_COOKIE)?.value);
}

/** Guard for admin pages and server actions. */
export async function requireAdmin(): Promise<string> {
  const admin = await getAdmin();
  if (!admin) redirect('/admin/login');
  return admin;
}
