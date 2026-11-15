'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';

const items = [
  { href: '/admin', label: 'Dashboard', exact: true },
  { href: '/admin/licenses', label: 'Lisensi' },
  { href: '/admin/releases', label: 'Rilis' },
  { href: '/admin/announcements', label: 'Pengumuman' },
  { href: '/admin/users', label: 'Pengguna' },
  { href: '/admin/reviews', label: 'Ulasan' },
];

export function AdminNav() {
  const pathname = usePathname();
  return (
    <nav className="console-nav" aria-label="Navigasi admin">
      {items.map((item) => {
        const active = item.exact ? pathname === item.href : pathname.startsWith(item.href);
        return (
          <Link key={item.href} href={item.href} className={active ? 'active' : undefined}>
            {item.label}
          </Link>
        );
      })}
      <Link href="/" target="_blank" className="muted">Lihat situs ↗</Link>
    </nav>
  );
}
