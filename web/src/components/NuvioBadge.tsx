/* eslint-disable @next/next/no-img-element */
/** The Nuvio logo badge shown next to a player's name (replaces the old "[Nuvio]" text). */
export function NuvioBadge({ size = 18 }: { size?: number }) {
  return <img src="/brand/badge.png" alt="Nuvio" title="Akun Nuvio" width={size} height={size} className="nuvio-badge" />;
}

export function PlayerName({ name, badge, size }: { name: string; badge: boolean; size?: number }) {
  return (
    <span className="player-name">
      {badge && <NuvioBadge size={size} />}
      <span>{name}</span>
    </span>
  );
}
