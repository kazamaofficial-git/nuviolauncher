import nodemailer from 'nodemailer';
import { env } from './env';

interface Mail {
  to: string;
  subject: string;
  text: string;
  html: string;
}

/**
 * Sends an e-mail through SMTP. Without SMTP settings it only logs the message in
 * development; in production it throws so a missing config is never silent.
 */
export async function sendMail({ to, subject, text, html }: Mail): Promise<void> {
  const host = env.smtpHost();
  if (!host) {
    if (process.env.NODE_ENV === 'production') {
      throw new Error('SMTP is not configured (SMTP_HOST).');
    }
    console.warn(`[mail:dev] to=${to} subject="${subject}"\n${text}`);
    return;
  }
  const transport = nodemailer.createTransport({
    host,
    port: env.smtpPort(),
    secure: env.smtpSecure(),
    auth: env.smtpUser() ? { user: env.smtpUser(), pass: env.smtpPass() } : undefined,
  });
  await transport.sendMail({ from: env.smtpFrom(), to, subject, text, html });
}

export async function sendOtpMail(to: string, code: string, username: string): Promise<void> {
  await sendMail({
    to,
    subject: `Kode verifikasi Nuvio: ${code}`,
    text: `Halo ${username},\n\nKode verifikasi Nuvio Anda: ${code}\nBerlaku 10 menit. Jika Anda tidak mendaftar, abaikan email ini.\n\nKazama Tech`,
    html: `<div style="font-family:system-ui,sans-serif;background:#05000d;color:#ede9fe;padding:32px">
      <h2 style="margin:0 0 12px">Verifikasi akun Nuvio</h2>
      <p>Halo ${escapeHtml(username)}, masukkan kode berikut di Nuvio:</p>
      <p style="font-size:34px;letter-spacing:8px;font-weight:700;color:#c4b5fd;margin:16px 0">${code}</p>
      <p style="color:#9d8fc0">Berlaku 10 menit. Jika Anda tidak mendaftar, abaikan email ini.</p>
      <p style="color:#9d8fc0">— Kazama Tech</p></div>`,
  });
}

function escapeHtml(s: string): string {
  return s.replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]!);
}
