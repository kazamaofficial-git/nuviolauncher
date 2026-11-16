'use client';

import Link from 'next/link';
import { useActionState } from 'react';
import {
  completeGoogleAction,
  loginAction,
  registerAction,
  resendOtpAction,
  verifyOtpAction,
  type FormState,
} from '@/app/(site)/account/actions';

const initial: FormState = {};

function Feedback({ state }: { state: FormState }) {
  return (
    <>
      {state.error && <p className="form-error" role="alert">{state.error}</p>}
      {state.message && <p className="form-ok">{state.message}</p>}
    </>
  );
}

export function RegisterForm({ next }: { next: string }) {
  const [state, action, pending] = useActionState(registerAction, initial);
  return (
    <form action={action} className="stack">
      <input type="hidden" name="next" value={next} />
      <label>Email
        <input className="input" type="email" name="email" autoComplete="email" required />
      </label>
      <label>Username (3–16 karakter)
        <input className="input" name="username" autoComplete="username" minLength={3} maxLength={16} pattern="[A-Za-z0-9_]{3,16}" required />
        <span className="muted small">Badge logo Nuvio tampil di samping nama Anda.</span>
      </label>
      <label>Kata sandi
        <input className="input" type="password" name="password" autoComplete="new-password" minLength={8} maxLength={72} required />
      </label>
      <label>Konfirmasi kata sandi
        <input className="input" type="password" name="confirmPassword" autoComplete="new-password" minLength={8} maxLength={72} required />
      </label>
      <Feedback state={state} />
      <button className="btn btn-block" type="submit" disabled={pending}>{pending ? 'Mendaftar…' : 'Daftar & kirim kode OTP'}</button>
    </form>
  );
}

export function AccountLoginForm({ next }: { next: string }) {
  const [state, action, pending] = useActionState(loginAction, initial);
  return (
    <form action={action} className="stack">
      <input type="hidden" name="next" value={next} />
      <label>Email atau username
        <input className="input" name="login" autoComplete="username" required />
      </label>
      <label>Kata sandi
        <input className="input" type="password" name="password" autoComplete="current-password" required />
      </label>
      <Feedback state={state} />
      <button className="btn btn-block" type="submit" disabled={pending}>{pending ? 'Memeriksa…' : 'Masuk'}</button>
      <p className="muted small center-text">Belum punya akun? <Link href={`/account/register?next=${encodeURIComponent(next)}`}>Daftar</Link></p>
    </form>
  );
}

export function VerifyForm({ email, next }: { email: string; next: string }) {
  const [state, action, pending] = useActionState(verifyOtpAction, initial);
  const [resendState, resend, resending] = useActionState(resendOtpAction, initial);
  return (
    <div className="stack">
      <form action={action} className="stack">
        <input type="hidden" name="email" value={email} />
        <input type="hidden" name="next" value={next} />
        <label>Kode OTP 6 digit
          <input className="input otp" name="code" inputMode="numeric" autoComplete="one-time-code" pattern="\d{6}" maxLength={6} required />
        </label>
        <Feedback state={state} />
        <button className="btn btn-block" type="submit" disabled={pending}>{pending ? 'Memverifikasi…' : 'Verifikasi'}</button>
      </form>
      <form action={resend} className="stack">
        <input type="hidden" name="email" value={email} />
        <Feedback state={resendState} />
        <button className="btn btn-ghost btn-block btn-sm" type="submit" disabled={resending}>Kirim ulang kode</button>
      </form>
    </div>
  );
}

export function CompleteGoogleForm({ next, email }: { next: string; email: string }) {
  const [state, action, pending] = useActionState(completeGoogleAction, initial);
  return (
    <form action={action} className="stack">
      <input type="hidden" name="next" value={next} />
      <p className="muted small">Masuk sebagai {email}. Pilih username untuk akun Nuvio Anda.</p>
      <label>Username (3–16 karakter)
        <input className="input" name="username" minLength={3} maxLength={16} pattern="[A-Za-z0-9_]{3,16}" required />
      </label>
      <Feedback state={state} />
      <button className="btn btn-block" type="submit" disabled={pending}>{pending ? 'Menyimpan…' : 'Selesai'}</button>
    </form>
  );
}
