'use server';

import bcrypt from 'bcryptjs';
import { timingSafeEqual } from 'node:crypto';
import { revalidatePath } from 'next/cache';
import { cookies, headers } from 'next/headers';
import { redirect } from 'next/navigation';
import {
  OTP_MAX_ATTEMPTS,
  OTP_RESEND_MS,
  OTP_TTL_MS,
  emailSchema,
  generateOtp,
  hashOtp,
  newProfileId,
  registerSchema,
  safeNext,
  usernameSchema,
} from '@/lib/account';
import { db } from '@/lib/db';
import { clientIp } from '@/lib/hash';
import { sendOtpMail } from '@/lib/mail';
import { rateLimit } from '@/lib/rate-limit';
import { TextureError, saveTexture, type TextureKind } from '@/lib/textures';
import { endUserSession, getCurrentUser, requireUser, startUserSession } from '@/lib/user-auth';
import { GOOGLE_SIGNUP_COOKIE, verifyGoogleSignup } from '@/lib/user-session';

export interface FormState {
  error?: string;
  message?: string;
}

const str = (fd: FormData, name: string) => String(fd.get(name) ?? '').trim();
const firstIssue = (e: { issues: { message: string }[] }) => e.issues[0]?.message ?? 'Data tidak valid.';

// ── OTP helper ───────────────────────────────────────────────

/** Creates and mails a fresh OTP. Returns false while the resend cooldown is active. */
async function sendOtp(user: { id: string; email: string; username: string }): Promise<boolean> {
  const recent = await db.emailOtp.findFirst({
    where: { userId: user.id, createdAt: { gt: new Date(Date.now() - OTP_RESEND_MS) } },
  });
  if (recent) return false;
  const code = generateOtp();
  await db.emailOtp.deleteMany({ where: { userId: user.id } });
  await db.emailOtp.create({
    data: { userId: user.id, codeHash: hashOtp(code, user.id), expiresAt: new Date(Date.now() + OTP_TTL_MS) },
  });
  await sendOtpMail(user.email, code, user.username);
  return true;
}

const verifyUrl = (email: string, next: string) =>
  `/account/verify?email=${encodeURIComponent(email)}&next=${encodeURIComponent(next)}`;

// ── Register / verify / login ────────────────────────────────

export async function registerAction(_prev: FormState, fd: FormData): Promise<FormState> {
  if (!rateLimit(`reg:${clientIp(await headers())}`, 5, 60 * 60_000)) {
    return { error: 'Terlalu banyak percobaan pendaftaran. Coba lagi nanti.' };
  }
  const parsed = registerSchema.safeParse({
    email: str(fd, 'email'),
    username: str(fd, 'username'),
    password: String(fd.get('password') ?? ''),
    confirmPassword: String(fd.get('confirmPassword') ?? ''),
  });
  if (!parsed.success) return { error: firstIssue(parsed.error) };
  const { email, username, password } = parsed.data;
  const next = safeNext(str(fd, 'next'));

  const byEmail = await db.user.findUnique({ where: { email } });
  if (byEmail?.emailVerified) return { error: 'Email sudah terdaftar. Silakan masuk.' };

  const byName = await db.user.findUnique({ where: { usernameLower: username.toLowerCase() } });
  if (byName && byName.id !== byEmail?.id) return { error: 'Username sudah dipakai.' };

  const passwordHash = await bcrypt.hash(password, 12);
  const user = byEmail
    ? await db.user.update({ where: { id: byEmail.id }, data: { username, usernameLower: username.toLowerCase(), passwordHash } })
    : await db.user.create({
        data: { email, username, usernameLower: username.toLowerCase(), passwordHash, profileId: newProfileId() },
      });

  try {
    await sendOtp(user);
  } catch {
    return { error: 'Gagal mengirim email verifikasi. Coba lagi beberapa saat.' };
  }
  redirect(verifyUrl(email, next));
}

export async function verifyOtpAction(_prev: FormState, fd: FormData): Promise<FormState> {
  const email = emailSchema.safeParse(str(fd, 'email'));
  const code = str(fd, 'code').replace(/\s/g, '');
  const next = safeNext(str(fd, 'next'));
  if (!email.success || !/^\d{6}$/.test(code)) return { error: 'Masukkan kode 6 digit.' };

  const user = await db.user.findUnique({ where: { email: email.data } });
  const otp = user ? await db.emailOtp.findFirst({ where: { userId: user.id }, orderBy: { createdAt: 'desc' } }) : null;
  if (!user || !otp || otp.expiresAt < new Date()) return { error: 'Kode kedaluwarsa. Minta kode baru.' };
  if (otp.attempts >= OTP_MAX_ATTEMPTS) return { error: 'Terlalu banyak percobaan. Minta kode baru.' };

  await db.emailOtp.update({ where: { id: otp.id }, data: { attempts: { increment: 1 } } });
  const a = Buffer.from(hashOtp(code, user.id));
  const b = Buffer.from(otp.codeHash);
  if (a.length !== b.length || !timingSafeEqual(a, b)) return { error: 'Kode salah.' };

  await db.user.update({ where: { id: user.id }, data: { emailVerified: true } });
  await db.emailOtp.deleteMany({ where: { userId: user.id } });
  await startUserSession(user.id);
  redirect(next);
}

export async function resendOtpAction(_prev: FormState, fd: FormData): Promise<FormState> {
  const email = emailSchema.safeParse(str(fd, 'email'));
  if (!email.success) return { error: 'Email tidak valid.' };
  const user = await db.user.findUnique({ where: { email: email.data } });
  if (!user || user.emailVerified) return { message: 'Jika email terdaftar, kode baru telah dikirim.' };
  try {
    const sent = await sendOtp(user);
    return sent ? { message: 'Kode baru telah dikirim.' } : { error: 'Tunggu 1 menit sebelum meminta kode lagi.' };
  } catch {
    return { error: 'Gagal mengirim email. Coba lagi.' };
  }
}

export async function loginAction(_prev: FormState, fd: FormData): Promise<FormState> {
  const login = str(fd, 'login').toLowerCase();
  const password = String(fd.get('password') ?? '');
  const next = safeNext(str(fd, 'next'));
  if (!login || !password) return { error: 'Isi email/username dan kata sandi.' };
  if (!rateLimit(`login:${clientIp(await headers())}:${login}`, 10, 15 * 60_000)) {
    return { error: 'Terlalu banyak percobaan. Coba lagi dalam 15 menit.' };
  }

  const user = await db.user.findFirst({ where: { OR: [{ email: login }, { usernameLower: login }] } });
  if (user && !user.passwordHash) {
    return { error: 'Akun ini terdaftar lewat Google. Gunakan tombol “Masuk dengan Google”.' };
  }
  // Always run bcrypt so timing does not reveal whether the account exists.
  const ok = await bcrypt.compare(password, user?.passwordHash ?? '$2a$12$invalidinvalidinvalidinvalidinvalidinvalidinvalidinva');
  if (!user || !ok) return { error: 'Email/username atau kata sandi salah.' };

  if (!user.emailVerified) {
    try { await sendOtp(user); } catch { /* the verify page lets them resend */ }
    redirect(verifyUrl(user.email, next));
  }
  await startUserSession(user.id);
  redirect(next);
}

export async function logoutAction(): Promise<void> {
  await endUserSession();
  redirect('/');
}

export async function completeGoogleAction(_prev: FormState, fd: FormData): Promise<FormState> {
  const signup = await verifyGoogleSignup((await cookies()).get(GOOGLE_SIGNUP_COOKIE)?.value);
  if (!signup) return { error: 'Sesi Google berakhir. Mulai lagi dari halaman masuk.' };
  const username = usernameSchema.safeParse(str(fd, 'username'));
  if (!username.success) return { error: firstIssue(username.error) };
  const next = safeNext(str(fd, 'next'));

  const taken = await db.user.findUnique({ where: { usernameLower: username.data.toLowerCase() } });
  if (taken) return { error: 'Username sudah dipakai.' };
  const existing = await db.user.findUnique({ where: { email: signup.email } });
  if (existing) return { error: 'Email sudah terdaftar. Masuk dengan kata sandi, lalu hubungkan Google.' };

  const user = await db.user.create({
    data: {
      email: signup.email,
      username: username.data,
      usernameLower: username.data.toLowerCase(),
      googleId: signup.googleId,
      emailVerified: true,
      profileId: newProfileId(),
    },
  });
  (await cookies()).delete(GOOGLE_SIGNUP_COOKIE);
  await startUserSession(user.id);
  redirect(next);
}

// ── Profile ──────────────────────────────────────────────────

export async function updateProfileAction(fd: FormData): Promise<void> {
  const user = await requireUser('/account');
  const model = str(fd, 'model') === 'slim' ? 'slim' : 'classic';
  await db.user.update({ where: { id: user.id }, data: { badge: fd.get('badge') === 'on', model } });
  revalidatePath('/account');
}

async function uploadTexture(kind: TextureKind, fd: FormData): Promise<FormState> {
  const user = await requireUser('/account');
  const file = fd.get('file');
  if (!(file instanceof File) || file.size === 0) return { error: 'Pilih berkas PNG terlebih dahulu.' };
  try {
    const hash = await saveTexture(kind, Buffer.from(await file.arrayBuffer()));
    await db.user.update({
      where: { id: user.id },
      data: kind === 'skin'
        ? { skinHash: hash, model: str(fd, 'model') === 'slim' ? 'slim' : 'classic' }
        : { capeHash: hash },
    });
  } catch (e) {
    return { error: e instanceof TextureError ? e.message : 'Gagal menyimpan berkas.' };
  }
  revalidatePath('/account');
  return { message: kind === 'skin' ? 'Skin diperbarui.' : 'Cape diperbarui.' };
}

export const uploadSkinAction = async (_p: FormState, fd: FormData) => uploadTexture('skin', fd);
export const uploadCapeAction = async (_p: FormState, fd: FormData) => uploadTexture('cape', fd);

export async function removeTextureAction(fd: FormData): Promise<void> {
  const user = await requireUser('/account');
  const kind = str(fd, 'kind');
  await db.user.update({
    where: { id: user.id },
    data: kind === 'cape' ? { capeHash: null } : { skinHash: null },
  });
  revalidatePath('/account');
}

export async function revokeSessionAction(fd: FormData): Promise<void> {
  const user = await requireUser('/account');
  await db.authToken.deleteMany({ where: { id: str(fd, 'id'), userId: user.id } });
  revalidatePath('/account');
}

// ── Launcher device link ─────────────────────────────────────

async function resolveLink(code: string) {
  return db.deviceLink.findFirst({
    where: { userCode: code.toUpperCase(), status: 'PENDING', expiresAt: { gt: new Date() } },
  });
}

export async function approveLinkAction(fd: FormData): Promise<void> {
  const code = str(fd, 'code');
  const user = await requireUser(`/account/link?code=${encodeURIComponent(code)}`);
  const link = await resolveLink(code);
  if (!link) redirect(`/account/link?code=${encodeURIComponent(code)}&state=invalid`);
  await db.deviceLink.update({ where: { id: link.id }, data: { status: 'APPROVED', userId: user.id } });
  redirect(`/account/link?code=${encodeURIComponent(code)}&state=done`);
}

export async function denyLinkAction(fd: FormData): Promise<void> {
  const code = str(fd, 'code');
  await getCurrentUser();
  const link = await resolveLink(code);
  if (link) await db.deviceLink.update({ where: { id: link.id }, data: { status: 'DENIED' } });
  redirect('/account');
}

