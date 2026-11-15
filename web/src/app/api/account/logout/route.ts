import { ok } from '@/lib/api';
import { bearer, revokeToken } from '@/lib/tokens';

export const dynamic = 'force-dynamic';

/** Revokes the launcher access token. Idempotent. */
export async function POST(req: Request) {
  const token = bearer(req);
  if (token) await revokeToken(token);
  return ok({});
}
