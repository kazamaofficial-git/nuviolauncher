import { readTexture } from '@/lib/textures';

export const dynamic = 'force-dynamic';

/** Serves uploaded skins/capes. Content-addressed, so they can be cached forever. */
export async function GET(_req: Request, { params }: { params: Promise<{ file: string }> }) {
  const { file } = await params;
  const hash = file.replace(/\.png$/, '');
  const data = await readTexture(hash);
  if (!data) return new Response('Not found', { status: 404 });
  return new Response(new Uint8Array(data), {
    headers: {
      'Content-Type': 'image/png',
      'Cache-Control': 'public, max-age=31536000, immutable',
      'Access-Control-Allow-Origin': '*',
      'X-Content-Type-Options': 'nosniff',
    },
  });
}
