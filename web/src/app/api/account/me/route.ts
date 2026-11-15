import { fail, ok } from '@/lib/api';
import { toLauncherProfile } from '@/lib/account';
import { bearer, resolveToken } from '@/lib/tokens';

export const dynamic = 'force-dynamic';

/** Current profile for a launcher access token (also used to detect revoked tokens). */
export async function GET(req: Request) {
  const resolved = await resolveToken(bearer(req));
  if (!resolved) return fail('TOKEN_INVALID', 'Sesi tidak valid. Masuk ulang.', 401);
  return ok({ profile: toLauncherProfile(resolved.user) });
}
