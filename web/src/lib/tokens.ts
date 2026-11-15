import { randomBytes } from 'node:crypto';
import type { User } from '@prisma/client';
import { db } from './db';
import { sha256 } from './account';

const TOKEN_TTL_MS = 30 * 24 * 60 * 60_000;

/** Creates an access token. The plaintext is returned once; only its hash is stored. */
export async function issueToken(userId: string, opts: { clientToken?: string; label?: string } = {}) {
  const plain = `nvt_${randomBytes(32).toString('hex')}`;
  await db.authToken.create({
    data: {
      userId,
      tokenHash: sha256(plain),
      clientToken: opts.clientToken ?? '',
      label: opts.label ?? '',
      expiresAt: new Date(Date.now() + TOKEN_TTL_MS),
    },
  });
  return plain;
}

/** Resolves a token to its user (or null when unknown, expired, or the account is unverified). */
export async function resolveToken(plain: string | null | undefined, clientToken?: string): Promise<{ user: User; tokenId: string } | null> {
  if (!plain) return null;
  const row = await db.authToken.findUnique({ where: { tokenHash: sha256(plain) }, include: { user: true } });
  if (!row || row.expiresAt < new Date() || !row.user.emailVerified) return null;
  if (clientToken && row.clientToken && row.clientToken !== clientToken) return null;
  // Touch at most once a minute to keep writes cheap.
  if (Date.now() - row.lastUsedAt.getTime() > 60_000) {
    await db.authToken.update({ where: { id: row.id }, data: { lastUsedAt: new Date() } });
  }
  return { user: row.user, tokenId: row.id };
}

export async function revokeToken(plain: string): Promise<void> {
  await db.authToken.deleteMany({ where: { tokenHash: sha256(plain) } });
}

export function bearer(req: Request): string | null {
  const header = req.headers.get('authorization') ?? '';
  return header.toLowerCase().startsWith('bearer ') ? header.slice(7).trim() : null;
}
