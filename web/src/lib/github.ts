import { env } from './env';

export type Platform = 'windows' | 'android' | 'macos';
export const platforms: readonly Platform[] = ['windows', 'android', 'macos'];

export interface ReleaseAsset {
  id: number;
  name: string;
  size: number;
}

export interface ReleaseInfo {
  tag: string;
  /** Tag without a leading "v". */
  version: string;
  prerelease: boolean;
  publishedAt: string;
  notes: string;
  assets: Partial<Record<Platform, ReleaseAsset>>;
}

interface GithubAsset {
  id: number;
  name: string;
  size: number;
}

interface GithubRelease {
  tag_name: string;
  draft: boolean;
  prerelease: boolean;
  published_at: string | null;
  created_at: string;
  body: string | null;
  assets: GithubAsset[];
}

const API = 'https://api.github.com';
const REVALIDATE_SECONDS = 300;

export const platformLabels: Record<Platform, string> = {
  windows: 'Windows 10/11 (64-bit)',
  android: 'Android 7.0+ (APK universal)',
  macos: 'macOS',
};

function authHeaders(): Record<string, string> {
  const token = env.githubToken();
  return {
    'User-Agent': 'nuvio-web',
    'X-GitHub-Api-Version': '2022-11-28',
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
  };
}

/** Maps a release file to a platform by its extension. */
export function classifyAsset(name: string): Platform | null {
  const n = name.toLowerCase();
  if (n.endsWith('.apk')) return 'android';
  if (n.endsWith('.exe') || n.endsWith('.msi')) return 'windows';
  if (n.endsWith('.dmg') || n.endsWith('.pkg')) return 'macos';
  return null;
}

function toRelease(r: GithubRelease): ReleaseInfo {
  const assets: ReleaseInfo['assets'] = {};
  for (const a of r.assets) {
    const platform = classifyAsset(a.name);
    if (!platform) continue;
    const current = assets[platform];
    // Prefer an installer ("setup") over any other Windows file.
    const better = !current || (platform === 'windows' && /setup|installer/i.test(a.name));
    if (better) assets[platform] = { id: a.id, name: a.name, size: a.size };
  }
  return {
    tag: r.tag_name,
    version: r.tag_name.replace(/^v/i, ''),
    prerelease: r.prerelease,
    publishedAt: r.published_at ?? r.created_at,
    notes: r.body ?? '',
    assets,
  };
}

/** Published releases, newest first. Returns [] when GitHub is not configured/unreachable. */
export async function getReleases(limit = 10): Promise<ReleaseInfo[]> {
  const repo = env.githubRepo();
  if (!repo) return [];
  try {
    const res = await fetch(`${API}/repos/${repo}/releases?per_page=${limit}`, {
      headers: { Accept: 'application/vnd.github+json', ...authHeaders() },
      next: { revalidate: REVALIDATE_SECONDS },
    });
    if (!res.ok) return [];
    const list = (await res.json()) as GithubRelease[];
    return list.filter((r) => !r.draft).map(toRelease);
  } catch {
    return [];
  }
}

/** Newest published release (pre-releases included while Nuvio is in beta). */
export async function getLatestRelease(): Promise<ReleaseInfo | null> {
  const [latest] = await getReleases(5);
  return latest ?? null;
}

/**
 * Opens the binary of a release asset as a stream. The caller proxies it to the
 * visitor, so the GitHub location never reaches the browser.
 */
export async function openAssetStream(assetId: number): Promise<Response> {
  return fetch(`${API}/repos/${env.githubRepo()}/releases/assets/${assetId}`, {
    headers: { Accept: 'application/octet-stream', ...authHeaders() },
    redirect: 'follow',
    cache: 'no-store',
  });
}
