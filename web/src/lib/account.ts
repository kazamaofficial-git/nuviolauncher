import { createHash, randomBytes, randomInt, randomUUID } from 'node:crypto';
import { z } from 'zod';
import type { User } from '@prisma/client';
import { env } from './env';

export const BADGE = '[Nuvio]';

/** 3-9 chars so "[Nuvio]" (7) + name never exceeds Minecraft's 16-char limit. */
export const usernameSchema = z
  .string()
  .trim()
  .regex(/^[A-Za-z0-9_]{3,9}$/, 'Username 3–9 karakter: huruf, angka, atau _');

export const emailSchema = z.string().trim().toLowerCase().email('Email tidak valid').max(120);

/** bcrypt only uses the first 72 bytes, so cap there. */
export const passwordSchema = z
  .string()
  .min(8, 'Kata sandi minimal 8 karakter')
  .max(72, 'Kata sandi maksimal 72 karakter');

export const registerSchema = z
  .object({
    email: emailSchema,
    username: usernameSchema,
    password: passwordSchema,
    confirmPassword: z.string(),
  })
  .refine((v) => v.password === v.confirmPassword, {
    path: ['confirmPassword'],
    message: 'Konfirmasi kata sandi tidak sama',
  });

/** Safe in-site redirect target (blocks open redirects). */
export function safeNext(next: string | null | undefined, fallback = '/account'): string {
  if (!next || !next.startsWith('/') || next.startsWith('//') || next.includes('\\')) return fallback;
  return next;
}

export function newProfileId(): string {
  return randomUUID().replace(/-/g, '');
}

/** The real in-game name (`--username`). */
export function inGameName(user: Pick<User, 'username' | 'badge'>): string {
  return user.badge ? `${BADGE}${user.username}` : user.username;
}

/** What the UI shows, e.g. "[Nuvio] Steve". */
export function displayName(user: Pick<User, 'username' | 'badge'>): string {
  return user.badge ? `${BADGE} ${user.username}` : user.username;
}

export function textureUrl(hash: string | null): string | null {
  return hash ? `${env.siteUrl()}/api/textures/${hash}.png` : null;
}

/** Profile payload for the launcher (see docs/ACCOUNTS.md). */
export function toLauncherProfile(user: User) {
  return {
    id: user.profileId,
    username: user.username,
    name: inGameName(user),
    displayName: displayName(user),
    badge: user.badge,
    model: user.model,
    skinUrl: textureUrl(user.skinHash),
    capeUrl: textureUrl(user.capeHash),
  };
}

export const sha256 = (value: string): string => createHash('sha256').update(value).digest('hex');

// ── OTP ──────────────────────────────────────────────────────

export const OTP_TTL_MS = 10 * 60_000;
export const OTP_RESEND_MS = 60_000;
export const OTP_MAX_ATTEMPTS = 5;

export function generateOtp(): string {
  return String(randomInt(0, 1_000_000)).padStart(6, '0');
}

export function hashOtp(code: string, userId: string): string {
  return sha256(`${code}|${userId}|${env.sessionSecret()}`);
}

// ── Tokens / codes ───────────────────────────────────────────

const CODE_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

/** ABCD-EFGH */
export function generateUserCode(): string {
  const pick = () => Array.from({ length: 4 }, () => CODE_ALPHABET[randomInt(CODE_ALPHABET.length)]).join('');
  return `${pick()}-${pick()}`;
}

export function generateSecret(bytes = 24): string {
  return randomBytes(bytes).toString('hex');
}
