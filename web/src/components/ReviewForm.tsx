'use client';

import { useState, type FormEvent } from 'react';

type Status = { kind: 'idle' } | { kind: 'sending' } | { kind: 'done' | 'error'; message: string };

export function ReviewForm() {
  const [open, setOpen] = useState(false);
  const [rating, setRating] = useState(5);
  const [status, setStatus] = useState<Status>({ kind: 'idle' });

  async function onSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const form = e.currentTarget;
    const data = new FormData(form);
    setStatus({ kind: 'sending' });
    try {
      const res = await fetch('/api/reviews', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name: data.get('name'),
          comment: data.get('comment'),
          platform: data.get('platform') ?? '',
          website: data.get('website') ?? '',
          rating,
        }),
      });
      const json = (await res.json()) as { ok: boolean; message: string };
      if (json.ok) {
        form.reset();
        setStatus({ kind: 'done', message: json.message });
      } else {
        setStatus({ kind: 'error', message: json.message });
      }
    } catch {
      setStatus({ kind: 'error', message: 'Gagal mengirim. Periksa koneksi Anda.' });
    }
  }

  if (!open) {
    return (
      <button type="button" className="btn btn-ghost btn-block" onClick={() => setOpen(true)}>
        Tulis ulasan
      </button>
    );
  }

  return (
    <form onSubmit={onSubmit} className="stack review-form">
      <div className="star-input" role="radiogroup" aria-label="Penilaian">
        {[1, 2, 3, 4, 5].map((n) => (
          <button
            key={n}
            type="button"
            role="radio"
            aria-checked={rating === n}
            aria-label={`${n} bintang`}
            className={n <= rating ? 'on' : undefined}
            onClick={() => setRating(n)}
          >
            ★
          </button>
        ))}
      </div>
      <input className="input" name="name" placeholder="Nama" minLength={2} maxLength={40} required />
      <select className="input" name="platform" defaultValue="">
        <option value="">Platform (opsional)</option>
        <option value="windows">Windows</option>
        <option value="android">Android</option>
      </select>
      <textarea className="input" name="comment" rows={3} placeholder="Ceritakan pengalaman Anda (min. 10 karakter)" minLength={10} maxLength={500} required />
      {/* Honeypot field: hidden from people, filled by bots. */}
      <input className="hp" name="website" tabIndex={-1} autoComplete="off" aria-hidden="true" />
      {status.kind === 'done' && <p className="form-ok">{status.message}</p>}
      {status.kind === 'error' && <p className="form-error" role="alert">{status.message}</p>}
      <button className="btn btn-block" type="submit" disabled={status.kind === 'sending'}>
        {status.kind === 'sending' ? 'Mengirim…' : 'Kirim ulasan'}
      </button>
    </form>
  );
}
