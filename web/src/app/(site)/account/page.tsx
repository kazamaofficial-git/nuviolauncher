import type { Metadata } from 'next';
import { PlayerName } from '@/components/NuvioBadge';
import { SkinPreview } from '@/components/account/SkinPreview';
import { TextureUpload } from '@/components/account/TextureUpload';
import { displayName, inGameName, textureUrl } from '@/lib/account';
import { db } from '@/lib/db';
import { formatDate } from '@/lib/format';
import { requireUser } from '@/lib/user-auth';
import { logoutAction, revokeSessionAction, updateProfileAction } from './actions';

export const metadata: Metadata = { title: 'Akun saya', robots: { index: false } };

export default async function AccountPage() {
  const user = await requireUser('/account');
  const sessions = await db.authToken.findMany({
    where: { userId: user.id, expiresAt: { gt: new Date() } },
    orderBy: { lastUsedAt: 'desc' },
    take: 20,
  });
  const skin = textureUrl(user.skinHash);
  const cape = textureUrl(user.capeHash);
  return (
    <section className="container account-grid">
      <aside className="panel glass center-text">
        <SkinPreview skinUrl={skin} capeUrl={cape} />
        <h2><PlayerName name={displayName(user)} badge={user.badge} size={24} /></h2>
        <p className="muted small">Nama di game: <code>{inGameName(user)}</code></p>
        <p className="muted small">UUID: <code>{user.profileId}</code></p>
        <form action={logoutAction}><button className="btn btn-ghost btn-sm" type="submit">Keluar</button></form>
      </aside>

      <div className="stack-lg">
        <div className="panel glass">
          <h2>Profil</h2>
          <form action={updateProfileAction} className="stack">
            <label className="check"><input type="checkbox" name="badge" defaultChecked={user.badge} /> Tampilkan badge logo Nuvio di samping nama</label>
            <fieldset className="hud-grid">
              <legend className="muted small">HUD badge di server dengan plugin NuvioSkins</legend>
              <label className="check"><input type="checkbox" name="hudName" defaultChecked={user.hudName} /> Di atas kepala (nametag)</label>
              <label className="check"><input type="checkbox" name="hudTab" defaultChecked={user.hudTab} /> Di daftar pemain (Tab)</label>
              <label className="check"><input type="checkbox" name="hudChat" defaultChecked={user.hudChat} /> Di chat</label>
            </fieldset>
            <label>Model lengan
              <select className="input" name="model" defaultValue={user.model}>
                <option value="classic">Classic (Steve)</option>
                <option value="slim">Slim (Alex)</option>
              </select>
            </label>
            <button className="btn btn-sm" type="submit">Simpan</button>
          </form>
        </div>
        <div className="panel glass"><h2>Skin</h2><TextureUpload kind="skin" hasTexture={Boolean(user.skinHash)} model={user.model} /></div>
        <div className="panel glass"><h2>Cape</h2><TextureUpload kind="cape" hasTexture={Boolean(user.capeHash)} /></div>
        <div className="panel glass">
          <h2>Sesi launcher</h2>
          {sessions.length === 0 && <p className="muted">Belum ada launcher yang terhubung.</p>}
          <ul className="list">
            {sessions.map((s) => (
              <li key={s.id} className="list-item">
                <span>{s.label || 'Nuvio Launcher'} <span className="muted small">· aktif {formatDate(s.lastUsedAt, true)}</span></span>
                <form action={revokeSessionAction}>
                  <input type="hidden" name="id" value={s.id} />
                  <button className="btn btn-ghost btn-sm" type="submit">Cabut</button>
                </form>
              </li>
            ))}
          </ul>
        </div>
      </div>
    </section>
  );
}
