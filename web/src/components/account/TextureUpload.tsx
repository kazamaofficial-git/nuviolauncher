'use client';

import { useActionState } from 'react';
import { removeTextureAction, uploadCapeAction, uploadSkinAction, type FormState } from '@/app/(site)/account/actions';

const initial: FormState = {};

interface Props {
  kind: 'skin' | 'cape';
  hasTexture: boolean;
  model?: string;
}

export function TextureUpload({ kind, hasTexture, model = 'classic' }: Props) {
  const [state, action, pending] = useActionState(kind === 'skin' ? uploadSkinAction : uploadCapeAction, initial);
  return (
    <div className="stack">
      <form action={action} className="stack">
        <label>{kind === 'skin' ? 'Berkas skin (PNG 64×64 atau 64×32)' : 'Berkas cape (PNG 64×32 atau 22×17)'}
          <input className="input" type="file" name="file" accept="image/png" required />
        </label>
        {kind === 'skin' && (
          <label>Model lengan
            <select className="input" name="model" defaultValue={model}>
              <option value="classic">Classic (Steve)</option>
              <option value="slim">Slim (Alex)</option>
            </select>
          </label>
        )}
        {state.error && <p className="form-error" role="alert">{state.error}</p>}
        {state.message && <p className="form-ok">{state.message}</p>}
        <button className="btn btn-sm" type="submit" disabled={pending}>{pending ? 'Mengunggah…' : 'Unggah'}</button>
      </form>
      {hasTexture && (
        <form action={removeTextureAction}>
          <input type="hidden" name="kind" value={kind} />
          <button className="btn btn-ghost btn-sm" type="submit">Hapus {kind}</button>
        </form>
      )}
    </div>
  );
}
