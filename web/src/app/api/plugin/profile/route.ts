import { NextResponse } from 'next/server';
import { db } from '@/lib/db';

export const dynamic = 'force-dynamic';

/**
 * Used by the NuvioSkins server plugin: `GET /api/plugin/profile?name=Steve`
 * -> { found, id, name, badge, hud: { nametag, tab, chat } }. Public data only.
 */
export async function GET(req: Request) {
  const name = new URL(req.url).searchParams.get('name')?.trim().toLowerCase() ?? '';
  if (!/^[a-z0-9_]{3,16}$/.test(name)) return NextResponse.json({ found: false });
  const user = await db.user.findUnique({ where: { usernameLower: name } });
  if (!user || !user.emailVerified) return NextResponse.json({ found: false });
  return NextResponse.json({
    found: true,
    id: user.profileId,
    name: user.username,
    badge: user.badge,
    hud: { nametag: user.hudName, tab: user.hudTab, chat: user.hudChat },
  });
}
