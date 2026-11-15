import type { User } from '@prisma/client';
import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import { db } from './db';
import { USER_COOKIE, USER_TTL_SECONDS, signUserSession, verifyUserSession } from './user-session';

export async function startUserSession(userId: string): Promise<void> {
  const jar = await cookies();
  jar.set(USER_COOKIE, await signUserSession(userId), {
    httpOnly: true,
    sameSite: 'lax',
    secure: process.env.NODE_ENV === 'production',
    path: '/',
    maxAge: USER_TTL_SECONDS,
  });
}

export async function endUserSession(): Promise<void> {
  (await cookies()).delete(USER_COOKIE);
}

/** The signed-in visitor, or null. Unverified accounts count as signed out. */
export async function getCurrentUser(): Promise<User | null> {
  const id = await verifyUserSession((await cookies()).get(USER_COOKIE)?.value);
  if (!id) return null;
  const user = await db.user.findUnique({ where: { id } });
  return user && user.emailVerified ? user : null;
}

/** Redirects to the login page (remembering `next`) when nobody is signed in. */
export async function requireUser(next: string): Promise<User> {
  const user = await getCurrentUser();
  if (!user) redirect(`/account/login?next=${encodeURIComponent(next)}`);
  return user;
}
