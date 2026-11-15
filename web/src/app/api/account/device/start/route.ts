import { fail, ok } from '@/lib/api';
import { generateSecret, generateUserCode, sha256 } from '@/lib/account';
import { db } from '@/lib/db';
import { env } from '@/lib/env';
import { clientIp } from '@/lib/hash';
import { rateLimit } from '@/lib/rate-limit';

export const dynamic = 'force-dynamic';

const EXPIRES_IN = 600;

/** Launcher starts a device link; the user approves it on the website. */
export async function POST(req: Request) {
  if (!rateLimit(`dlink:${clientIp(req.headers)}`, 10, 60_000)) {
    return fail('RATE_LIMITED', 'Terlalu banyak permintaan. Coba lagi sebentar.', 429);
  }
  const deviceCode = generateSecret(24);
  const userCode = generateUserCode();
  try {
    await db.deviceLink.create({
      data: {
        deviceHash: sha256(deviceCode),
        userCode,
        expiresAt: new Date(Date.now() + EXPIRES_IN * 1000),
      },
    });
  } catch {
    return fail('SERVER_ERROR', 'Gagal membuat kode. Coba lagi.', 500);
  }
  return ok({
    deviceCode,
    userCode,
    verificationUrl: `${env.siteUrl()}/account/link?code=${userCode}`,
    expiresIn: EXPIRES_IN,
    interval: 3,
  });
}
