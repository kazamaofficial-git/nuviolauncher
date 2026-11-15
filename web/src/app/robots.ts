import type { MetadataRoute } from 'next';
import { env } from '@/lib/env';

/** Served at /robots.txt and points crawlers to the sitemap. */
export default function robots(): MetadataRoute.Robots {
  const base = env.siteUrl();
  return {
    rules: [{ userAgent: '*', allow: '/', disallow: ['/admin', '/api/'] }],
    sitemap: `${base}/sitemap.xml`,
    host: base,
  };
}
