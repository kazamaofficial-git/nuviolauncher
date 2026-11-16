import { SiteFooter } from '@/components/SiteFooter';
import { SiteHeader } from '@/components/SiteHeader';
import { Starfield } from '@/components/Starfield';
import { displayName } from '@/lib/account';
import { getLatestRelease } from '@/lib/github';
import { getCurrentUser } from '@/lib/user-auth';

export default async function SiteLayout({ children }: { children: React.ReactNode }) {
  const [release, user] = await Promise.all([getLatestRelease(), getCurrentUser()]);
  return (
    <>
      <Starfield />
      <div className="nebula" aria-hidden="true" />
      <SiteHeader version={release?.version} userName={user ? displayName(user) : null} badge={user?.badge} />
      <main className="site-main">{children}</main>
      <SiteFooter />
    </>
  );
}
