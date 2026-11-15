import { fail, ok } from '@/lib/api';
import { db } from '@/lib/db';

export const dynamic = 'force-dynamic';

/** Active announcements for the app's home screen (max 10, newest first). */
export async function GET() {
  try {
    const rows = await db.announcement.findMany({
      where: { active: true },
      orderBy: { createdAt: 'desc' },
      take: 10,
    });
    return ok(
      {
        items: rows.map((a) => ({
          id: a.id,
          title: a.title,
          body: a.body,
          level: a.level,
          createdAt: a.createdAt.toISOString(),
        })),
      },
      { headers: { 'Cache-Control': 'public, max-age=60' } },
    );
  } catch {
    return fail('SERVER_ERROR', 'Terjadi kesalahan pada server.', 500);
  }
}
