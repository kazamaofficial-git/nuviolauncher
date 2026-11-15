import { NextResponse } from 'next/server';
import { clientIp } from '@/lib/hash';
import { db } from '@/lib/db';
import { getLatestRelease, openAssetStream, platforms, type Platform } from '@/lib/github';
import { rateLimit } from '@/lib/rate-limit';

export const dynamic = 'force-dynamic';

/**
 * Streams the latest build for a platform through this server, so the visitor only
 * ever sees this site's URL. Each served download is counted.
 */
export async function GET(req: Request, { params }: { params: Promise<{ platform: string }> }) {
  const { platform } = await params;
  if (!platforms.includes(platform as Platform)) {
    return NextResponse.json({ ok: false, message: 'Platform tidak dikenal.' }, { status: 404 });
  }
  if (!rateLimit(`dl:${clientIp(req.headers)}`, 20, 60_000)) {
    return NextResponse.json({ ok: false, message: 'Terlalu banyak permintaan.' }, { status: 429 });
  }

  const release = await getLatestRelease();
  const asset = release?.assets[platform as Platform];
  if (!release || !asset) {
    return NextResponse.json(
      { ok: false, message: 'Build untuk platform ini belum tersedia.' },
      { status: 404 },
    );
  }

  const upstream = await openAssetStream(asset.id);
  if (!upstream.ok || !upstream.body) {
    return NextResponse.json({ ok: false, message: 'Gagal mengambil berkas.' }, { status: 502 });
  }

  // Count only after the upstream confirmed the file exists. Never block the download on it.
  void db.downloadEvent
    .create({ data: { platform, version: release.version } })
    .catch(() => undefined);

  return new Response(upstream.body, {
    headers: {
      'Content-Type': 'application/octet-stream',
      'Content-Disposition': `attachment; filename="${asset.name.replace(/"/g, '')}"`,
      'Content-Length': String(asset.size),
      'Cache-Control': 'no-store',
      'X-Content-Type-Options': 'nosniff',
    },
  });
}
