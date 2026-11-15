import { NextResponse } from 'next/server';
import { db } from '@/lib/db';
import { yggProfile } from '@/lib/yggdrasil';

export const dynamic = 'force-dynamic';

/** Public profile lookup (skin/cape textures). `?unsigned=false` adds the signature. */
export async function GET(req: Request, { params }: { params: Promise<{ uuid: string }> }) {
  const { uuid } = await params;
  const id = uuid.replace(/-/g, '').toLowerCase();
  if (!/^[a-f0-9]{32}$/.test(id)) return new NextResponse(null, { status: 204 });
  const user = await db.user.findUnique({ where: { profileId: id } });
  if (!user || !user.emailVerified) return new NextResponse(null, { status: 204 });
  const unsigned = new URL(req.url).searchParams.get('unsigned') !== 'false';
  return NextResponse.json(yggProfile(user, { signed: !unsigned }));
}
