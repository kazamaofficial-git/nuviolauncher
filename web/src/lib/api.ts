import { NextResponse } from 'next/server';
import type { ZodType } from 'zod';

export type ErrorCode =
  | 'INVALID_REQUEST'
  | 'LICENSE_NOT_FOUND'
  | 'LICENSE_REVOKED'
  | 'LICENSE_EXPIRED'
  | 'DEVICE_LIMIT_REACHED'
  | 'DEVICE_NOT_ACTIVATED'
  | 'RATE_LIMITED'
  | 'DEVICE_CODE_EXPIRED'
  | 'ACCESS_DENIED'
  | 'TOKEN_INVALID'
  | 'UNAUTHORIZED'
  | 'SERVER_ERROR';

/** `{ ok: true, ...data }` — matches docs/API.md. */
export function ok<T extends object>(data: T, init?: ResponseInit) {
  return NextResponse.json({ ok: true, ...data }, init);
}

/** `{ ok: false, code, message }` — matches docs/API.md. */
export function fail(code: ErrorCode, message: string, status = 400) {
  return NextResponse.json({ ok: false, code, message }, { status });
}

/** Parses and validates a JSON body; returns a ready-made error response on failure. */
export async function parseBody<T>(
  req: Request,
  schema: ZodType<T>,
): Promise<{ data: T } | { error: NextResponse }> {
  let raw: unknown;
  try {
    raw = await req.json();
  } catch {
    return { error: fail('INVALID_REQUEST', 'Body must be valid JSON.') };
  }
  const parsed = schema.safeParse(raw);
  if (!parsed.success) {
    const first = parsed.error.issues[0];
    const where = first?.path.join('.') || 'body';
    return { error: fail('INVALID_REQUEST', `Invalid ${where}: ${first?.message ?? 'bad value'}`) };
  }
  return { data: parsed.data };
}
