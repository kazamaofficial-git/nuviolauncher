'use server';

import { revalidatePath } from 'next/cache';
import { headers } from 'next/headers';
import { redirect } from 'next/navigation';
import { z } from 'zod';
import { checkCredentials, endSession, requireAdmin, startSession } from '@/lib/auth';
import { db } from '@/lib/db';
import { clientIp } from '@/lib/hash';
import { generateLicenseKey } from '@/lib/license';
import { rateLimit } from '@/lib/rate-limit';

export interface FormState {
  error?: string;
  message?: string;
  keys?: string[];
}

const str = (fd: FormData, name: string) => String(fd.get(name) ?? '').trim();

// ── Session ──────────────────────────────────────────────────

export async function loginAction(_prev: FormState, formData: FormData): Promise<FormState> {
  const ip = clientIp(await headers());
  if (!rateLimit(`login:${ip}`, 5, 15 * 60_000)) {
    return { error: 'Terlalu banyak percobaan. Coba lagi dalam 15 menit.' };
  }
  const email = str(formData, 'email');
  const password = String(formData.get('password') ?? '');
  if (!(await checkCredentials(email, password))) {
    return { error: 'Email atau kata sandi salah.' };
  }
  await startSession(email);
  redirect('/admin');
}

export async function logoutAction(): Promise<void> {
  await endSession();
  redirect('/admin/login');
}

// ── Licences ─────────────────────────────────────────────────

const generateSchema = z.object({
  count: z.coerce.number().int().min(1).max(100),
  maxDevices: z.coerce.number().int().min(1).max(20),
  /** 0 = lifetime */
  days: z.coerce.number().int().min(0).max(3650),
  note: z.string().max(200),
  email: z.string().max(120),
});

export async function generateLicensesAction(
  _prev: FormState,
  formData: FormData,
): Promise<FormState> {
  await requireAdmin();
  const parsed = generateSchema.safeParse({
    count: str(formData, 'count'),
    maxDevices: str(formData, 'maxDevices'),
    days: str(formData, 'days') || '0',
    note: str(formData, 'note'),
    email: str(formData, 'email'),
  });
  if (!parsed.success) return { error: 'Data tidak valid. Periksa jumlah, perangkat, dan masa berlaku.' };

  const { count, maxDevices, days, note, email } = parsed.data;
  const expiresAt = days > 0 ? new Date(Date.now() + days * 86_400_000) : null;
  const keys: string[] = [];

  while (keys.length < count) {
    const key = generateLicenseKey();
    try {
      await db.license.create({ data: { key, maxDevices, expiresAt, note, email } });
      keys.push(key);
    } catch {
      // Unique collision (astronomically rare): try another key.
    }
  }
  revalidatePath('/admin/licenses');
  revalidatePath('/admin');
  return { message: `${keys.length} lisensi dibuat.`, keys };
}

const updateSchema = z.object({
  id: z.string().min(1),
  maxDevices: z.coerce.number().int().min(1).max(20),
  expires: z.string(),
  note: z.string().max(200),
  email: z.string().max(120),
});

export async function updateLicenseAction(formData: FormData): Promise<void> {
  await requireAdmin();
  const parsed = updateSchema.safeParse({
    id: str(formData, 'id'),
    maxDevices: str(formData, 'maxDevices'),
    expires: str(formData, 'expires'),
    note: str(formData, 'note'),
    email: str(formData, 'email'),
  });
  if (!parsed.success) return;
  const { id, maxDevices, expires, note, email } = parsed.data;
  const expiresAt = expires ? new Date(`${expires}T23:59:59.000Z`) : null;
  await db.license.update({
    where: { id },
    data: { maxDevices, expiresAt: expiresAt && !Number.isNaN(expiresAt.getTime()) ? expiresAt : null, note, email },
  });
  revalidatePath(`/admin/licenses/${id}`);
  revalidatePath('/admin/licenses');
}

export async function setLicenseStatusAction(formData: FormData): Promise<void> {
  await requireAdmin();
  const id = str(formData, 'id');
  const status = str(formData, 'status') === 'REVOKED' ? 'REVOKED' : 'ACTIVE';
  await db.license.update({ where: { id }, data: { status } });
  revalidatePath(`/admin/licenses/${id}`);
  revalidatePath('/admin/licenses');
  revalidatePath('/admin');
}

export async function deleteLicenseAction(formData: FormData): Promise<void> {
  await requireAdmin();
  await db.license.delete({ where: { id: str(formData, 'id') } });
  revalidatePath('/admin/licenses');
  revalidatePath('/admin');
  redirect('/admin/licenses');
}

export async function removeActivationAction(formData: FormData): Promise<void> {
  await requireAdmin();
  const licenseId = str(formData, 'licenseId');
  await db.activation.delete({ where: { id: str(formData, 'id') } });
  revalidatePath(`/admin/licenses/${licenseId}`);
}

// ── Announcements ────────────────────────────────────────────

const announcementSchema = z.object({
  title: z.string().min(2).max(120),
  body: z.string().min(2).max(1000),
  level: z.enum(['info', 'warning', 'success']),
});

export async function createAnnouncementAction(
  _prev: FormState,
  formData: FormData,
): Promise<FormState> {
  await requireAdmin();
  const parsed = announcementSchema.safeParse({
    title: str(formData, 'title'),
    body: str(formData, 'body'),
    level: str(formData, 'level') || 'info',
  });
  if (!parsed.success) return { error: 'Judul (min 2) dan isi (min 2) wajib diisi.' };
  await db.announcement.create({ data: parsed.data });
  revalidatePath('/admin/announcements');
  return { message: 'Pengumuman dipublikasikan.' };
}

export async function toggleAnnouncementAction(formData: FormData): Promise<void> {
  await requireAdmin();
  const id = str(formData, 'id');
  const current = await db.announcement.findUnique({ where: { id } });
  if (!current) return;
  await db.announcement.update({ where: { id }, data: { active: !current.active } });
  revalidatePath('/admin/announcements');
}

export async function deleteAnnouncementAction(formData: FormData): Promise<void> {
  await requireAdmin();
  await db.announcement.delete({ where: { id: str(formData, 'id') } });
  revalidatePath('/admin/announcements');
}

// ── Reviews ──────────────────────────────────────────────────

export async function setReviewStatusAction(formData: FormData): Promise<void> {
  await requireAdmin();
  const status = str(formData, 'status');
  if (!['PENDING', 'APPROVED', 'HIDDEN'].includes(status)) return;
  await db.review.update({ where: { id: str(formData, 'id') }, data: { status } });
  revalidatePath('/admin/reviews');
  revalidatePath('/admin');
  revalidatePath('/');
}

export async function deleteReviewAction(formData: FormData): Promise<void> {
  await requireAdmin();
  await db.review.delete({ where: { id: str(formData, 'id') } });
  revalidatePath('/admin/reviews');
  revalidatePath('/');
}
