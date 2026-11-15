'use client';

import { useActionState } from 'react';
import { loginAction, type FormState } from '@/app/admin/actions';

const initial: FormState = {};

export function LoginForm() {
  const [state, action, pending] = useActionState(loginAction, initial);
  return (
    <form action={action} className="stack">
      <label>Email
        <input className="input" type="email" name="email" autoComplete="username" required />
      </label>
      <label>Kata sandi
        <input className="input" type="password" name="password" autoComplete="current-password" required />
      </label>
      {state.error && <p className="form-error" role="alert">{state.error}</p>}
      <button className="btn btn-block" type="submit" disabled={pending}>
        {pending ? 'Memeriksa…' : 'Masuk'}
      </button>
    </form>
  );
}
