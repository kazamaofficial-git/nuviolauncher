import Link from 'next/link';

export default function NotFound() {
  return (
    <main className="login-shell">
      <div className="login-card glass center">
        <h1>404</h1>
        <p className="muted">Halaman tidak ditemukan.</p>
        <Link href="/" className="btn">Kembali ke beranda</Link>
      </div>
    </main>
  );
}
