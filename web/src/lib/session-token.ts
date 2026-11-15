import { SignJWT, jwtVerify } from 'jose';
import { env } from './env';

/** Edge-safe session helpers (used by middleware and server code). */
export const SESSION_COOKIE = 'nuvio_admin';
export const SESSION_TTL_SECONDS = 60 * 60 * 12;

const key = () => new TextEncoder().encode(env.sessionSecret());

export async function signSession(email: string): Promise<string> {
  return new SignJWT({ role: 'admin' })
    .setProtectedHeader({ alg: 'HS256' })
    .setSubject(email)
    .setIssuedAt()
    .setExpirationTime(`${SESSION_TTL_SECONDS}s`)
    .sign(key());
}

/** Returns the admin e-mail when the token is valid, otherwise null. */
export async function verifySession(token: string | undefined): Promise<string | null> {
  if (!token) return null;
  try {
    const { payload } = await jwtVerify(token, key(), { algorithms: ['HS256'] });
    return payload.role === 'admin' && typeof payload.sub === 'string' ? payload.sub : null;
  } catch {
    return null;
  }
}
