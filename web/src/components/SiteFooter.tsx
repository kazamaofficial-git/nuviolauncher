import Image from 'next/image';
import Link from 'next/link';
import { site } from '@/lib/site';

export function SiteFooter() {
  return (
    <footer className="site-footer">
      <div className="container footer-grid">
        <div className="footer-brand">
          <Image src="/brand/kazamatech-white.png" alt="Kazama Tech" width={96} height={106} />
          <p className="muted small">
            {site.name} dikembangkan oleh {site.developer}. Nuvio bukan produk resmi Mojang Studios
            atau Microsoft. Minecraft adalah merek dagang Mojang Studios.
          </p>
        </div>
        <nav aria-label="Produk">
          <h3>Produk</h3>
          <Link href="/download">Unduh</Link>
          <Link href="/plus">Nuvio Plus</Link>
          <Link href="/changelog">Catatan rilis</Link>
        </nav>
        <nav aria-label="Informasi">
          <h3>Informasi</h3>
          <Link href="/#faq">FAQ</Link>
          <Link href="/privacy">Kebijakan privasi</Link>
          <Link href="/terms">Syarat penggunaan</Link>
        </nav>
      </div>
      <div className="container footer-bottom muted small">
        © {new Date().getFullYear()} {site.developer}. Hak cipta dilindungi.
      </div>
    </footer>
  );
}
