import { z } from 'zod';
import { fail, ok, parseBody } from '@/lib/api';
import { sha256, toLauncherProfile } from '@/lib/account';
import { db } from '@/lib/db';
import { clientIp } from '@/lib/hash';
import { rateLimit } from '@/lib/rate-limit';
import { issueToken } from '@/lib/tokens';

export const dynamic = 'force-dynamic';

const schema = z.object({ deviceCode: z.string().min(16).max(128) });

/** Launcher polls until the website approves the link. The token is issued exactly once. */
export async function POST(req: Request) {
  if (!rateLimit(`dpoll:${clientIp(req.headers)}`, 60, 60_000)) {
    return fail('RATE_LIMITED', 'Terlalu banyak permintaan.', 429);
  }
  const parsed = await parseBody(req, schema);
  if ('error' in parsed) return parsed.error;

  const link = await db.deviceLink.findUnique({
    where: { deviceHash: sha256(parsed.data.deviceCode) },
    include: { user: true },
  });
  if (!link || link.expiresAt < new Date() || link.status === 'CONSUMED') {
    return fail('DEVICE_CODE_EXPIRED', 'Kode sudah kedaluwarsa. Mulai ulang proses masuk.', 410);
  }
  if (link.status === 'DENIED') return fail('ACCESS_DENIED', 'Permintaan ditolak di website.', 403);
  if (link.status === 'PENDING' || !link.user) return ok({ status: 'pending' });

  // APPROVED → claim atomically so a replayed poll cannot mint a second token.
  const claimed = await db.deviceLink.updateMany({
    where: { id: link.id, status: 'APPROVED' },
    data: { status: 'CONSUMED' },
  });
  if (claimed.count !== 1) return fail('DEVICE_CODE_EXPIRED', 'Kode sudah digunakan.', 410);

  const accessToken = await issueToken(link.user.id, { label: 'Nuvio Launcher' });
  return ok({ status: 'approved', accessToken, profile: toLauncherProfile(link.user) });
}
