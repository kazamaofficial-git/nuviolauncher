import { SignJWT, jwtVerify } from 'jose';
import { env } from './env';

/** Website visitor sessions (distinct `role` claim from admin sessions). */
export const USER_COOKIE = 'nuvio_user';
export const GOOGLE_SIGNUP_COOKIE = 'nuvio_gsignup';
export const GOOGLE_STATE_COOKIE = 'nuvio_gstate';
export const USER_TTL_SECONDS = 60 * 60 * 24 * 30;

const key = () => new TextEncoder().encode(env.sessionSecret());

export async function signUserSession(userId: string): Promise<string> {
  return new SignJWT({ role: 'user' })
    .setProtectedHeader({ alg: 'HS256' })
    .setSubject(userId)
    .setIssuedAt()
    .setExpirationTime(`${USER_TTL_SECONDS}s`)
    .sign(key());
}

export async function verifyUserSession(token: string | undefined): Promise<string | null> {
  if (!token) return null;
  try {
    const { payload } = await jwtVerify(token, key(), { algorithms: ['HS256'] });
    return payload.role === 'user' && typeof payload.sub === 'string' ? payload.sub : null;
  } catch {
    return null;
  }
}

export interface GoogleSignup {
  googleId: string;
  email: string;
}

export async function signGoogleSignup(data: GoogleSignup): Promise<string> {
  return new SignJWT({ role: 'google-signup', email: data.email })
    .setProtectedHeader({ alg: 'HS256' })
    .setSubject(data.googleId)
    .setExpirationTime('15m')
    .sign(key());
}

export async function verifyGoogleSignup(token: string | undefined): Promise<GoogleSignup | null> {
  if (!token) return null;
  try {
    const { payload } = await jwtVerify(token, key(), { algorithms: ['HS256'] });
    if (payload.role !== 'google-signup' || typeof payload.sub !== 'string') return null;
    return { googleId: payload.sub, email: String(payload.email ?? '') };
  } catch {
    return null;
  }
}
