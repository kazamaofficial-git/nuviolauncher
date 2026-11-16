import Image from 'next/image';
import Link from 'next/link';
import { PlayerName } from '@/components/NuvioBadge';
import { navLinks } from '@/lib/site';

export function SiteHeader({ version, userName, badge }: { version?: string; userName?: string | null; badge?: boolean }) {
  return (
    <header className="site-header">
      <div className="container header-inner glass">
        <Link href="/" className="brand" aria-label="Nuvio Launcher — beranda">
          <Image src="/brand/nuvio-icon.png" alt="" width={40} height={40} priority />
          <span className="brand-text">
            <strong>Nuvio Launcher</strong>
            <span className="muted small">Windows &amp; Android</span>
          </span>
          {version && <span className="chip chip-ok">v{version}</span>}
        </Link>
        <nav className="nav" aria-label="Navigasi utama">
          {navLinks.map((l) => (
            <Link key={l.href} href={l.href}>{l.label}</Link>
          ))}
        </nav>
        <div className="header-cta">
          {userName
            ? <Link href="/account" className="btn btn-ghost btn-sm"><PlayerName name={userName} badge={Boolean(badge)} size={16} /></Link>
            : <Link href="/account/login" className="btn btn-ghost btn-sm">Masuk</Link>}
          <Link href="/download" className="btn btn-sm">Unduh</Link>
        </div>
      </div>
    </header>
  );
}
