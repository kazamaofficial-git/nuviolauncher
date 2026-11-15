import { createPrivateKey, createPublicKey, generateKeyPairSync, sign, type KeyObject } from 'node:crypto';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import type { User } from '@prisma/client';
import { NextResponse } from 'next/server';
import { inGameName, textureUrl } from './account';
import { env } from './env';

/** Yggdrasil-style error body used by authlib / authlib-injector. */
export function yggError(status: number, error: string, errorMessage: string) {
  return NextResponse.json({ error, errorMessage }, { status });
}

export const forbidden = (message = 'Invalid credentials or token.') =>
  yggError(403, 'ForbiddenOperationException', message);

let cachedKey: KeyObject | null = null;

/** RSA key used to sign profile properties. From env, from file, or generated once. */
export function signingKey(): KeyObject {
  if (cachedKey) return cachedKey;
  const fromEnv = env.yggdrasilPrivateKey();
  if (fromEnv) return (cachedKey = createPrivateKey(fromEnv));

  const file = path.resolve(env.yggdrasilKeyFile());
  if (existsSync(file)) return (cachedKey = createPrivateKey(readFileSync(file)));

  const { privateKey } = generateKeyPairSync('rsa', { modulusLength: 4096 });
  mkdirSync(path.dirname(file), { recursive: true });
  writeFileSync(file, privateKey.export({ type: 'pkcs8', format: 'pem' }), { mode: 0o600 });
  return (cachedKey = privateKey);
}

export function publicKeyPem(): string {
  return createPublicKey(signingKey()).export({ type: 'spki', format: 'pem' }).toString();
}

interface ProfileOptions {
  /** Include the (signed) textures property. */
  textures?: boolean;
  /** Sign the property (hasJoined and profile?unsigned=false). */
  signed?: boolean;
}

/** Yggdrasil profile (id/name + optional signed `textures` property). */
export function yggProfile(user: User, { textures = true, signed = false }: ProfileOptions = {}) {
  const base = { id: user.profileId, name: inGameName(user) };
  if (!textures) return base;

  const skin = textureUrl(user.skinHash);
  const cape = textureUrl(user.capeHash);
  const value = Buffer.from(
    JSON.stringify({
      timestamp: Date.now(),
      profileId: user.profileId,
      profileName: base.name,
      textures: {
        ...(skin ? { SKIN: { url: skin, ...(user.model === 'slim' ? { metadata: { model: 'slim' } } : {}) } } : {}),
        ...(cape ? { CAPE: { url: cape } } : {}),
      },
    }),
  ).toString('base64');

  const property: { name: string; value: string; signature?: string } = { name: 'textures', value };
  if (signed) property.signature = sign('RSA-SHA1', Buffer.from(value), signingKey()).toString('base64');
  return { ...base, properties: [property] };
}

/** Case-insensitive lookup key for an in-game name or plain username. */
export function stripBadge(name: string): string {
  return name.replace(/^\[nuvio\]/i, '').toLowerCase();
}
