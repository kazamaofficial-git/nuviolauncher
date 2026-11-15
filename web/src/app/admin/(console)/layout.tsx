import type { Metadata } from 'next';
import Image from 'next/image';
import { AdminNav } from '@/components/admin/AdminNav';
import { logoutAction } from '../actions';
import { requireAdmin } from '@/lib/auth';

export const metadata: Metadata = {
  title: { default: 'Console', template: '%s · Nuvio Console' },
  robots: { index: false, follow: false },
};

export const dynamic = 'force-dynamic';

export default async function ConsoleLayout({ children }: { children: React.ReactNode }) {
  const admin = await requireAdmin();
  return (
    <div className="console">
      <aside className="console-side">
        <div className="console-brand">
          <Image src="/brand/nuvio-icon.png" alt="" width={36} height={36} />
          <div>
            <strong>Nuvio Console</strong>
            <span className="muted small">Kazama Tech</span>
          </div>
        </div>
        <AdminNav />
        <div className="console-user">
          <span className="muted small" title={admin}>{admin}</span>
          <form action={logoutAction}>
            <button className="btn btn-ghost btn-sm" type="submit">Keluar</button>
          </form>
        </div>
      </aside>
      <main className="console-main">{children}</main>
    </div>
  );
}
