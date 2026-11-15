import { createHash } from 'node:crypto';
import { env } from './env';

/** Client IP from reverse-proxy headers (falls back to "unknown"). */
export function clientIp(headers: Headers): string {
  const forwarded = headers.get('x-forwarded-for');
  if (forwarded) return forwarded.split(',')[0]!.trim();
  return headers.get('x-real-ip') ?? 'unknown';
}

/** Salted hash so raw IP addresses are never stored. */
export function hashIp(ip: string): string {
  return createHash('sha256').update(`${ip}|${env.sessionSecret()}`).digest('hex').slice(0, 32);
}
