import { NextResponse } from 'next/server';
import { z } from 'zod';
import { db } from '@/lib/db';
import { resolveToken } from '@/lib/tokens';
import { forbidden, yggError } from '@/lib/yggdrasil';

export const dynamic = 'force-dynamic';

const schema = z.object({
  accessToken: z.string().min(1).max(200),
  selectedProfile: z.string().min(1).max(40),
  serverId: z.string().min(1).max(100),
});

/** The client announces it is joining `serverId`; `hasJoined` later confirms it. */
export async function POST(req: Request) {
  const parsed = schema.safeParse(await req.json().catch(() => null));
  if (!parsed.success) return yggError(400, 'IllegalArgumentException', 'Invalid request.');
  const resolved = await resolveToken(parsed.data.accessToken);
  if (!resolved || resolved.user.profileId !== parsed.data.selectedProfile.replace(/-/g, '')) {
    return forbidden('Invalid token.');
  }
  await db.sessionJoin.deleteMany({ where: { createdAt: { lt: new Date(Date.now() - 5 * 60_000) } } });
  await db.sessionJoin.create({ data: { serverId: parsed.data.serverId, userId: resolved.user.id } });
  return new NextResponse(null, { status: 204 });
}
