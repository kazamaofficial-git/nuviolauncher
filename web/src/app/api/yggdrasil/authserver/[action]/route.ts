import { NextResponse } from 'next/server';
import { z } from 'zod';
import bcrypt from 'bcryptjs';
import { db } from '@/lib/db';
import { clientIp } from '@/lib/hash';
import { rateLimit } from '@/lib/rate-limit';
import { issueToken, resolveToken, revokeToken } from '@/lib/tokens';
import { forbidden, stripBadge, yggError, yggProfile } from '@/lib/yggdrasil';

export const dynamic = 'force-dynamic';

const credentials = z.object({
  username: z.string().min(1).max(120),
  password: z.string().min(1).max(200),
  clientToken: z.string().max(100).optional(),
  requestUser: z.boolean().optional(),
});
const tokenBody = z.object({
  accessToken: z.string().min(1).max(200),
  clientToken: z.string().max(100).optional(),
  requestUser: z.boolean().optional(),
});

const noContent = () => new NextResponse(null, { status: 204 });

async function findByLogin(login: string) {
  const key = login.trim().toLowerCase();
  return db.user.findFirst({ where: { OR: [{ email: key }, { usernameLower: stripBadge(key) }] } });
}

/** Yggdrasil auth server: authenticate | refresh | validate | invalidate | signout. */
export async function POST(req: Request, { params }: { params: Promise<{ action: string }> }) {
  const { action } = await params;
  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return yggError(400, 'IllegalArgumentException', 'Invalid JSON.');
  }

  if (action === 'authenticate' || action === 'signout') {
    if (!rateLimit(`ygg:${clientIp(req.headers)}`, 10, 60_000)) {
      return yggError(429, 'ForbiddenOperationException', 'Too many attempts.');
    }
    const parsed = credentials.safeParse(body);
    if (!parsed.success) return yggError(400, 'IllegalArgumentException', 'Invalid request.');
    const user = await findByLogin(parsed.data.username);
    const ok = user?.passwordHash ? await bcrypt.compare(parsed.data.password, user.passwordHash) : false;
    if (!user || !ok || !user.emailVerified) return forbidden('Invalid credentials.');

    if (action === 'signout') {
      await db.authToken.deleteMany({ where: { userId: user.id } });
      return noContent();
    }
    const clientToken = parsed.data.clientToken ?? crypto.randomUUID().replace(/-/g, '');
    const accessToken = await issueToken(user.id, { clientToken, label: 'Yggdrasil' });
    const profile = yggProfile(user, { textures: false });
    return NextResponse.json({
      accessToken,
      clientToken,
      availableProfiles: [profile],
      selectedProfile: profile,
      ...(parsed.data.requestUser ? { user: { id: user.profileId, properties: [] } } : {}),
    });
  }

  const parsed = tokenBody.safeParse(body);
  if (!parsed.success) return yggError(400, 'IllegalArgumentException', 'Invalid request.');
  const { accessToken, clientToken } = parsed.data;

  switch (action) {
    case 'validate': {
      const resolved = await resolveToken(accessToken, clientToken);
      return resolved ? noContent() : forbidden('Invalid token.');
    }
    case 'invalidate': {
      await revokeToken(accessToken);
      return noContent();
    }
    case 'refresh': {
      const resolved = await resolveToken(accessToken, clientToken);
      if (!resolved) return forbidden('Invalid token.');
      await revokeToken(accessToken);
      const next = await issueToken(resolved.user.id, { clientToken: clientToken ?? '', label: 'Yggdrasil' });
      const profile = yggProfile(resolved.user, { textures: false });
      return NextResponse.json({
        accessToken: next,
        clientToken: clientToken ?? '',
        selectedProfile: profile,
        ...(parsed.data.requestUser ? { user: { id: resolved.user.profileId, properties: [] } } : {}),
      });
    }
    default:
      return yggError(404, 'NotFound', 'Unknown action.');
  }
}

