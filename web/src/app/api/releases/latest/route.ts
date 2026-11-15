import { fail, ok } from '@/lib/api';
import { getLatestRelease, platformLabels, platforms } from '@/lib/github';

export const dynamic = 'force-dynamic';

/** Latest release summary for the app's update check. */
export async function GET() {
  const release = await getLatestRelease();
  if (!release) return fail('SERVER_ERROR', 'Belum ada rilis yang tersedia.', 404);

  const entries = platforms.flatMap((p) => {
    const asset = release.assets[p];
    return asset
      ? [[p, { label: platformLabels[p], size: asset.size, url: `/api/download/${p}` }] as const]
      : [];
  });

  return ok(
    {
      version: release.version,
      prerelease: release.prerelease,
      publishedAt: release.publishedAt,
      notes: release.notes,
      platforms: Object.fromEntries(entries),
    },
    { headers: { 'Cache-Control': 'public, max-age=60' } },
  );
}
