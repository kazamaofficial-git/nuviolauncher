import { randomInt } from 'node:crypto';
import { z } from 'zod';
import type { Activation, License } from '@prisma/client';
import { db } from './db';
import type { ErrorCode } from './api';

const ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

/** NUVIO-XXXX-XXXX-XXXX using an unambiguous alphabet (no 0/O/1/I). */
export function generateLicenseKey(): string {
  const group = () =>
    Array.from({ length: 4 }, () => ALPHABET[randomInt(ALPHABET.length)]).join('');
  return `NUVIO-${group()}-${group()}-${group()}`;
}

export function normalizeKey(raw: string): string {
  return raw.trim().toUpperCase();
}

/** NUVIO-ABCD-EFGH-IJKL -> NUVIO-ABCD-••••-IJKL */
export function maskKey(key: string): string {
  const parts = key.split('-');
  if (parts.length !== 4) return '••••';
  return `${parts[0]}-${parts[1]}-••••-${parts[3]}`;
}

export function parseFeatures(features: string): string[] {
  return features
    .split(',')
    .map((f) => f.trim())
    .filter(Boolean);
}

const keySchema = z
  .string()
  .min(8)
  .max(40)
  .transform(normalizeKey);

const deviceSchema = z.object({
  deviceId: z.string().min(8).max(64),
  appVersion: z.string().max(40).default(''),
});

export const activateSchema = deviceSchema.extend({
  key: keySchema,
  deviceName: z.string().max(80).default(''),
  platform: z.enum(['windows', 'android', 'macos', 'linux']).default('windows'),
});

export const validateSchema = deviceSchema.extend({ key: keySchema });

export const deactivateSchema = z.object({
  key: keySchema,
  deviceId: z.string().min(8).max(64),
});

export interface LicenseFailure {
  code: ErrorCode;
  message: string;
  status: number;
}

/** Returns a failure if the licence cannot be used right now. */
export function checkUsable(license: License | null, now = new Date()): LicenseFailure | null {
  if (!license) {
    return { code: 'LICENSE_NOT_FOUND', message: 'Kunci lisensi tidak ditemukan.', status: 404 };
  }
  if (license.status !== 'ACTIVE') {
    return { code: 'LICENSE_REVOKED', message: 'Lisensi ini telah dicabut.', status: 403 };
  }
  if (license.expiresAt && license.expiresAt.getTime() < now.getTime()) {
    return { code: 'LICENSE_EXPIRED', message: 'Lisensi ini sudah kedaluwarsa.', status: 403 };
  }
  return null;
}

/** Licence payload sent to the app (see docs/API.md). */
export function toLicenseInfo(license: License, devicesUsed: number) {
  return {
    keyMasked: maskKey(license.key),
    plan: license.plan,
    features: parseFeatures(license.features),
    expiresAt: license.expiresAt ? license.expiresAt.toISOString() : null,
    maxDevices: license.maxDevices,
    devicesUsed,
  };
}

export type ActivationResult =
  | { ok: true; license: License; devicesUsed: number }
  | { ok: false; failure: LicenseFailure };

interface DeviceInput {
  deviceId: string;
  deviceName?: string;
  platform?: string;
  appVersion?: string;
}

/** Activates a device (idempotent) or refreshes it when already activated. */
export async function activateDevice(key: string, device: DeviceInput): Promise<ActivationResult> {
  const license = await db.license.findUnique({ where: { key } });
  const failure = checkUsable(license);
  if (failure || !license) {
    return { ok: false, failure: failure! };
  }

  const existing = await db.activation.findUnique({
    where: { licenseId_deviceId: { licenseId: license.id, deviceId: device.deviceId } },
  });

  if (!existing) {
    const used = await db.activation.count({ where: { licenseId: license.id } });
    if (used >= license.maxDevices) {
      return {
        ok: false,
        failure: {
          code: 'DEVICE_LIMIT_REACHED',
          message: `Batas perangkat tercapai (${license.maxDevices}). Nonaktifkan perangkat lain terlebih dahulu.`,
          status: 403,
        },
      };
    }
    await db.activation.create({
      data: {
        licenseId: license.id,
        deviceId: device.deviceId,
        deviceName: device.deviceName ?? '',
        platform: device.platform ?? '',
        appVersion: device.appVersion ?? '',
      },
    });
  } else {
    await db.activation.update({
      where: { id: existing.id },
      data: {
        lastSeenAt: new Date(),
        appVersion: device.appVersion ?? existing.appVersion,
        deviceName: device.deviceName || existing.deviceName,
      },
    });
  }

  const devicesUsed = await db.activation.count({ where: { licenseId: license.id } });
  return { ok: true, license, devicesUsed };
}

/** Re-validates an already activated device. */
export async function validateDevice(key: string, device: DeviceInput): Promise<ActivationResult> {
  const license = await db.license.findUnique({ where: { key } });
  const failure = checkUsable(license);
  if (failure || !license) {
    return { ok: false, failure: failure! };
  }

  const activation: Activation | null = await db.activation.findUnique({
    where: { licenseId_deviceId: { licenseId: license.id, deviceId: device.deviceId } },
  });
  if (!activation) {
    return {
      ok: false,
      failure: {
        code: 'DEVICE_NOT_ACTIVATED',
        message: 'Perangkat ini belum diaktifkan untuk lisensi tersebut.',
        status: 403,
      },
    };
  }

  await db.activation.update({
    where: { id: activation.id },
    data: { lastSeenAt: new Date(), appVersion: device.appVersion ?? activation.appVersion },
  });
  const devicesUsed = await db.activation.count({ where: { licenseId: license.id } });
  return { ok: true, license, devicesUsed };
}
