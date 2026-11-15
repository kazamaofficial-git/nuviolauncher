import { NextResponse } from 'next/server';
import { db } from '@/lib/db';
import { stripBadge, yggProfile } from '@/lib/yggdrasil';

export const dynamic = 'force-dynamic';

/** Server-side check: did `username` announce a join for `serverId` in the last 30 s? */
export async function GET(req: Request) {
  const q = new URL(req.url).searchParams;
  const username = q.get('username');
  const serverId = q.get('serverId');
  if (!username || !serverId) return new NextResponse(null, { status: 204 });

  const user = await db.user.findUnique({ where: { usernameLower: stripBadge(username) } });
  if (!user) return new NextResponse(null, { status: 204 });

  const join = await db.sessionJoin.findFirst({
    where: { serverId, userId: user.id, createdAt: { gte: new Date(Date.now() - 30_000) } },
    orderBy: { createdAt: 'desc' },
  });
  if (!join) return new NextResponse(null, { status: 204 });
  return NextResponse.json(yggProfile(user, { signed: true }));
}
