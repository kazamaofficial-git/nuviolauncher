const sizeUnits = ['B', 'KB', 'MB', 'GB'];

/** 54321000 -> "51.8 MB" */
export function formatBytes(bytes: number): string {
  if (!Number.isFinite(bytes) || bytes <= 0) return '—';
  let value = bytes;
  let unit = 0;
  while (value >= 1024 && unit < sizeUnits.length - 1) {
    value /= 1024;
    unit += 1;
  }
  return `${value.toFixed(unit === 0 ? 0 : 1)} ${sizeUnits[unit]}`;
}

export function formatDate(date: Date | string, withTime = false): string {
  const d = typeof date === 'string' ? new Date(date) : date;
  return new Intl.DateTimeFormat('id-ID', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    ...(withTime ? { hour: '2-digit', minute: '2-digit' } : {}),
    timeZone: 'Asia/Jakarta',
  }).format(d);
}

export function formatNumber(n: number): string {
  return new Intl.NumberFormat('id-ID').format(n);
}

/** "2 jam lalu", "3 hari lalu" */
export function timeAgo(date: Date | string): string {
  const d = typeof date === 'string' ? new Date(date) : date;
  const seconds = Math.max(0, Math.floor((Date.now() - d.getTime()) / 1000));
  const steps: [number, string][] = [
    [60, 'detik'],
    [60, 'menit'],
    [24, 'jam'],
    [30, 'hari'],
    [12, 'bulan'],
  ];
  let value = seconds;
  for (const [div, label] of steps) {
    if (value < div) return `${value} ${label} lalu`;
    value = Math.floor(value / div);
  }
  return `${value} tahun lalu`;
}
