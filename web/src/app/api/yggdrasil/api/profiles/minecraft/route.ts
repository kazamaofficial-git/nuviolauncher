import { NextResponse } from 'next/server';
import { z } from 'zod';
import { db } from '@/lib/db';
import { inGameName } from '@/lib/account';
import { stripBadge, yggError } from '@/lib/yggdrasil';

export const dynamic = 'force-dynamic';

const schema = z.array(z.string().min(1).max(40)).max(100);

/** Bulk name → profile id lookup. */
export async function POST(req: Request) {
  const parsed = schema.safeParse(await req.json().catch(() => null));
  if (!parsed.success) return yggError(400, 'IllegalArgumentException', 'Invalid request.');
  const keys = [...new Set(parsed.data.map(stripBadge))];
  const users = await db.user.findMany({ where: { usernameLower: { in: keys }, emailVerified: true } });
  return NextResponse.json(users.map((u) => ({ id: u.profileId, name: inGameName(u) })));
}
