'use client';

import { useActionState } from 'react';
import { createAnnouncementAction, type FormState } from '@/app/admin/actions';

const initial: FormState = {};

export function AnnouncementForm() {
  const [state, action, pending] = useActionState(createAnnouncementAction, initial);
  return (
    <section className="panel glass">
      <h2>Pengumuman baru</h2>
      <form action={action} className="stack">
        <label>Judul
          <input className="input" name="title" maxLength={120} required />
        </label>
        <label>Isi
          <textarea className="input" name="body" rows={3} maxLength={1000} required />
        </label>
        <label>Tingkat
          <select className="input" name="level" defaultValue="info">
            <option value="info">Info</option>
            <option value="success">Sukses</option>
            <option value="warning">Peringatan</option>
          </select>
        </label>
        {state.error && <p className="form-error" role="alert">{state.error}</p>}
        {state.message && <p className="form-ok">{state.message}</p>}
        <div><button className="btn" type="submit" disabled={pending}>{pending ? 'Menyimpan…' : 'Publikasikan'}</button></div>
      </form>
    </section>
  );
}
