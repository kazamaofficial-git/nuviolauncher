/** Static brand/site facts shared by pages, metadata and structured data. */
export const site = {
  name: 'Nuvio Launcher',
  developer: 'Kazama Tech',
  tagline: 'Launcher Minecraft futuristik untuk Windows & Android',
  description:
    'Nuvio Launcher adalah launcher Minecraft Java Edition bergaya neon futuristik dari Kazama Tech: unduhan paralel, instance terisolasi, dan satu lisensi Plus untuk PC & Android. Versi beta.',
  keywords: [
    'Nuvio Launcher',
    'Minecraft launcher',
    'launcher Minecraft Android',
    'launcher Minecraft Windows',
    'Minecraft Java Edition',
    'Kazama Tech',
    'download launcher Minecraft',
  ],
  locale: 'id_ID',
} as const;

export const navLinks = [
  { href: '/#fitur', label: 'Fitur' },
  { href: '/#spesifikasi', label: 'Spesifikasi' },
  { href: '/plus', label: 'Plus' },
  { href: '/#ulasan', label: 'Ulasan' },
  { href: '/#faq', label: 'FAQ' },
] as const;

/** Public routes that belong in sitemap.xml. */
export const publicRoutes = [
  { path: '/', priority: 1, changeFrequency: 'weekly' },
  { path: '/download', priority: 0.9, changeFrequency: 'weekly' },
  { path: '/plus', priority: 0.7, changeFrequency: 'monthly' },
  { path: '/changelog', priority: 0.6, changeFrequency: 'weekly' },
  { path: '/privacy', priority: 0.3, changeFrequency: 'yearly' },
  { path: '/terms', priority: 0.3, changeFrequency: 'yearly' },
] as const;
