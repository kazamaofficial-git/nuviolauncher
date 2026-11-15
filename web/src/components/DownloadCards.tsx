import Link from 'next/link';
import { formatBytes } from '@/lib/format';
import { platformLabels, type Platform, type ReleaseInfo } from '@/lib/github';
import { IconAndroid, IconDownload, IconWindows } from './Icons';

const config: { platform: Extract<Platform, 'windows' | 'android'>; name: string; Icon: typeof IconWindows }[] = [
  { platform: 'windows', name: 'Windows', Icon: IconWindows },
  { platform: 'android', name: 'Android', Icon: IconAndroid },
];

/** The two main download buttons, driven by the latest GitHub release. */
export function DownloadCards({ release, compact = false }: { release: ReleaseInfo | null; compact?: boolean }) {
  return (
    <div className={compact ? 'dl-grid dl-compact' : 'dl-grid'}>
      {config.map(({ platform, name, Icon }) => {
        const asset = release?.assets[platform];
        const body = (
          <>
            <span className="dl-icon"><Icon size={28} /></span>
            <span className="dl-text">
              <strong>Unduh {name}</strong>
              <span className="muted small">
                {asset && release
                  ? `v${release.version} · ${formatBytes(asset.size)}`
                  : 'Segera hadir'}
              </span>
              {!compact && <span className="muted small">{platformLabels[platform]}</span>}
            </span>
            <span className="dl-arrow"><IconDownload size={20} /></span>
          </>
        );
        return asset ? (
          <Link key={platform} href={`/api/download/${platform}`} className="dl-card glass" prefetch={false}>
            {body}
          </Link>
        ) : (
          <div key={platform} className="dl-card glass disabled" aria-disabled="true">{body}</div>
        );
      })}
    </div>
  );
}
