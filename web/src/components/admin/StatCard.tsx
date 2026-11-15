import Link from 'next/link';

interface Props {
  label: string;
  value: string;
  hint?: string;
  href?: string;
}

export function StatCard({ label, value, hint, href }: Props) {
  const body = (
    <>
      <span className="stat-label">{label}</span>
      <span className="stat-value">{value}</span>
      {hint && <span className="muted small">{hint}</span>}
    </>
  );
  return href ? (
    <Link href={href} className="stat-card glass">{body}</Link>
  ) : (
    <div className="stat-card glass">{body}</div>
  );
}
