import type { MetadataRoute } from 'next';
import { env } from '@/lib/env';
import { publicRoutes } from '@/lib/site';

/** Served at /sitemap.xml. Only public, indexable pages are listed. */
export default function sitemap(): MetadataRoute.Sitemap {
  const base = env.siteUrl();
  const lastModified = new Date();
  return publicRoutes.map((r) => ({
    url: `${base}${r.path === '/' ? '' : r.path}`,
    lastModified,
    changeFrequency: r.changeFrequency,
    priority: r.priority,
  }));
}
