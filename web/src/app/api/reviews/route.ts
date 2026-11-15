import { z } from 'zod';
import { fail, ok, parseBody } from '@/lib/api';
import { db } from '@/lib/db';
import { clientIp, hashIp } from '@/lib/hash';
import { rateLimit } from '@/lib/rate-limit';

export const dynamic = 'force-dynamic';

const reviewSchema = z.object({
  name: z.string().trim().min(2).max(40),
  rating: z.number().int().min(1).max(5),
  comment: z.string().trim().min(10).max(500),
  platform: z.enum(['windows', 'android', '']).default(''),
  /** Honeypot: real users leave this empty. */
  website: z.string().max(0).default(''),
});

/** Public review submission. Reviews stay PENDING until approved in the admin console. */
export async function POST(req: Request) {
  const ip = clientIp(req.headers);
  if (!rateLimit(`review:${ip}`, 5, 60_000)) {
    return fail('RATE_LIMITED', 'Terlalu banyak permintaan.', 429);
  }
  const parsed = await parseBody(req, reviewSchema);
  if ('error' in parsed) return parsed.error;

  const ipHash = hashIp(ip);
  const since = new Date(Date.now() - 24 * 60 * 60 * 1000);
  const recent = await db.review.count({ where: { ipHash, createdAt: { gte: since } } });
  if (recent >= 1) {
    return fail('RATE_LIMITED', 'Anda sudah mengirim ulasan dalam 24 jam terakhir.', 429);
  }

  const { name, rating, comment, platform } = parsed.data;
  await db.review.create({ data: { name, rating, comment, platform, ipHash } });
  return ok({ message: 'Terima kasih! Ulasan Anda akan tampil setelah dimoderasi.' });
}
