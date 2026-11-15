import { fail, ok, parseBody } from '@/lib/api';
import { db } from '@/lib/db';
import { clientIp } from '@/lib/hash';
import { deactivateSchema } from '@/lib/license';
import { rateLimit } from '@/lib/rate-limit';

export const dynamic = 'force-dynamic';

/** Frees one device slot. Idempotent: unknown keys/devices still return ok. */
export async function POST(req: Request) {
  if (!rateLimit(`license:${clientIp(req.headers)}`, 30, 60_000)) {
    return fail('RATE_LIMITED', 'Terlalu banyak permintaan. Coba lagi sebentar.', 429);
  }
  const parsed = await parseBody(req, deactivateSchema);
  if ('error' in parsed) return parsed.error;

  try {
    const license = await db.license.findUnique({ where: { key: parsed.data.key } });
    if (license) {
      await db.activation.deleteMany({
        where: { licenseId: license.id, deviceId: parsed.data.deviceId },
      });
    }
    return ok({});
  } catch {
    return fail('SERVER_ERROR', 'Terjadi kesalahan pada server.', 500);
  }
}
