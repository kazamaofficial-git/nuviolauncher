'use client';

import { useActionState } from 'react';
import { generateLicensesAction, type FormState } from '@/app/admin/actions';

const initial: FormState = {};

export function LicenseGenerator() {
  const [state, action, pending] = useActionState(generateLicensesAction, initial);
  return (
    <section className="panel glass">
      <h2>Buat lisensi</h2>
      <form action={action} className="form-grid">
        <label>Jumlah
          <input className="input" type="number" name="count" min={1} max={100} defaultValue={1} required />
        </label>
        <label>Maks. perangkat
          <input className="input" type="number" name="maxDevices" min={1} max={20} defaultValue={2} required />
        </label>
        <label>Masa berlaku (hari, 0 = seumur hidup)
          <input className="input" type="number" name="days" min={0} max={3650} defaultValue={0} />
        </label>
        <label>Email pembeli (opsional)
          <input className="input" name="email" maxLength={120} />
        </label>
        <label className="span-2">Catatan (opsional)
          <input className="input" name="note" maxLength={200} placeholder="mis. Order #123" />
        </label>
        <div className="form-actions">
          <button className="btn" type="submit" disabled={pending}>
            {pending ? 'Membuat…' : 'Buat kunci'}
          </button>
        </div>
      </form>
      {state.error && <p className="form-error" role="alert">{state.error}</p>}
      {state.keys && (
        <div className="keys-box">
          <p>{state.message}</p>
          <textarea className="input mono" readOnly rows={Math.min(state.keys.length, 8)} value={state.keys.join('\n')} />
        </div>
      )}
    </section>
  );
}
