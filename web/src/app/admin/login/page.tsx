import type { Metadata } from 'next';
import Image from 'next/image';
import { LoginForm } from '@/components/admin/LoginForm';

export const metadata: Metadata = {
  title: 'Masuk Admin',
  robots: { index: false, follow: false },
};

export default function AdminLoginPage() {
  return (
    <main className="login-shell">
      <div className="login-card glass">
        <Image src="/brand/nuvio-mark.png" alt="Nuvio" width={96} height={63} priority />
        <h1>Nuvio Console</h1>
        <p className="muted">Masuk untuk mengelola lisensi, rilis, dan pengumuman.</p>
        <LoginForm />
      </div>
    </main>
  );
}
