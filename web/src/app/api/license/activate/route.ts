import { fail, ok, parseBody } from '@/lib/api';
import { clientIp } from '@/lib/hash';
import { activateDevice, activateSchema, toLicenseInfo } from '@/lib/license';
import { rateLimit } from '@/lib/rate-limit';

export const dynamic = 'force-dynamic';

export async function POST(req: Request) {
  if (!rateLimit(`license:${clientIp(req.headers)}`, 30, 60_000)) {
    return fail('RATE_LIMITED', 'Terlalu banyak permintaan. Coba lagi sebentar.', 429);
  }
  const parsed = await parseBody(req, activateSchema);
  if ('error' in parsed) return parsed.error;

  try {
    const result = await activateDevice(parsed.data.key, parsed.data);
    if (!result.ok) {
      return fail(result.failure.code, result.failure.message, result.failure.status);
    }
    return ok({
      license: toLicenseInfo(result.license, result.devicesUsed),
      checkedAt: new Date().toISOString(),
    });
  } catch {
    return fail('SERVER_ERROR', 'Terjadi kesalahan pada server.', 500);
  }
}
