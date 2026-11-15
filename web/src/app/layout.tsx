import type { Metadata, Viewport } from 'next';
import { Inter, Rajdhani } from 'next/font/google';
import { env } from '@/lib/env';
import { site } from '@/lib/site';
import '@/styles/tokens.css';
import '@/styles/base.css';
import '@/styles/components.css';
import '@/styles/landing.css';
import '@/styles/admin.css';
import '@/styles/account.css';

const body = Inter({ subsets: ['latin'], variable: '--font-body', display: 'swap' });
const display = Rajdhani({
  subsets: ['latin'],
  weight: ['500', '600', '700'],
  variable: '--font-display',
  display: 'swap',
});

export const metadata: Metadata = {
  metadataBase: new URL(env.siteUrl()),
  title: { default: `${site.name} — ${site.tagline}`, template: `%s · ${site.name}` },
  description: site.description,
  keywords: [...site.keywords],
  applicationName: site.name,
  authors: [{ name: site.developer }],
  creator: site.developer,
  alternates: { canonical: '/' },
  openGraph: {
    type: 'website',
    siteName: site.name,
    locale: site.locale,
    title: `${site.name} — ${site.tagline}`,
    description: site.description,
    images: [{ url: '/og-image.png', width: 1200, height: 630, alt: site.name }],
  },
  twitter: {
    card: 'summary_large_image',
    title: `${site.name} — ${site.tagline}`,
    description: site.description,
    images: ['/og-image.png'],
  },
  icons: {
    icon: [{ url: '/favicon.ico' }, { url: '/icon-192.png', sizes: '192x192', type: 'image/png' }],
    apple: '/apple-touch-icon.png',
  },
  robots: { index: true, follow: true },
};

export const viewport: Viewport = {
  themeColor: '#05000d',
  colorScheme: 'dark',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="id" className={`${body.variable} ${display.variable}`}>
      <body>{children}</body>
    </html>
  );
}
