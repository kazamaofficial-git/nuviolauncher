import Link from 'next/link';
import { AppMockup } from '@/components/AppMockup';
import { DownloadCards } from '@/components/DownloadCards';
import { Faq } from '@/components/Faq';
import { IconAndroid, IconCheck, IconShield, IconWindows, featureIcons } from '@/components/Icons';
import { JsonLd } from '@/components/JsonLd';
import { OrbitalLogo } from '@/components/OrbitalLogo';
import { ReviewsSection } from '@/components/ReviewsSection';
import { StatsStrip } from '@/components/StatsStrip';
import { compareRows, faqs, features, specs } from '@/content/landing';
import { db } from '@/lib/db';
import { env } from '@/lib/env';
import { formatNumber } from '@/lib/format';
import { getLatestRelease } from '@/lib/github';
import { site } from '@/lib/site';

export const dynamic = 'force-dynamic';

const statusLabel = { ready: 'Tersedia', beta: 'Beta', soon: 'Segera' } as const;

async function safeCount(): Promise<number> {
  try {
    return await db.downloadEvent.count();
  } catch {
    return 0;
  }
}

export default async function HomePage() {
  const [release, downloads] = await Promise.all([getLatestRelease(), safeCount()]);
  const siteUrl = env.siteUrl();

  return (
    <>
      <JsonLd
        data={{
          '@context': 'https://schema.org',
          '@type': 'SoftwareApplication',
          name: site.name,
          applicationCategory: 'GameApplication',
          operatingSystem: 'Windows 10, Windows 11, Android 7.0+',
          description: site.description,
          url: siteUrl,
          image: `${siteUrl}/og-image.png`,
          ...(release ? { softwareVersion: release.version } : {}),
          offers: { '@type': 'Offer', price: '0', priceCurrency: 'USD' },
          author: { '@type': 'Organization', name: site.developer },
        }}
      />
      <JsonLd
        data={{
          '@context': 'https://schema.org',
          '@type': 'FAQPage',
          mainEntity: faqs.map((f) => ({
            '@type': 'Question',
            name: f.q,
            acceptedAnswer: { '@type': 'Answer', text: f.a },
          })),
        }}
      />

      {/* Hero */}
      <section className="hero container">
        <div className="hero-copy">
          <div className="chip-row">
            <span className="chip chip-warn">BETA</span>
            {release && (
              <span className="chip chip-ok">
                {release.assets.windows && `Win v${release.version}`}
                {release.assets.windows && release.assets.android && ' / '}
                {release.assets.android && `Android v${release.version}`}
              </span>
            )}
            {downloads > 0 && <span className="chip">{formatNumber(downloads)} unduhan</span>}
          </div>
          <h1>
            Launcher Minecraft <span className="grad">Futuristik</span> untuk Windows &amp; Android
          </h1>
          <p className="lead">
            Nuvio Launcher dari {site.developer}: antarmuka neon bernuansa galaksi, unduhan paralel,
            instance terisolasi, dan satu lisensi Plus untuk PC &amp; Android.
          </p>
          <DownloadCards release={release} />
          <ul className="trust">
            <li><IconCheck size={16} /> Gratis digunakan</li>
            <li><IconCheck size={16} /> Tanpa iklan</li>
            <li><IconShield size={16} /> Unduh resmi dari situs ini</li>
          </ul>
        </div>
        <div className="hero-art">
          <OrbitalLogo />
        </div>
      </section>

      <StatsStrip />

      {/* App preview (landscape) */}
      <section className="container preview" aria-label="Pratinjau aplikasi">
        <AppMockup version={release?.version} />
      </section>

      {/* Features */}
      <section id="fitur" className="section container">
        <div className="section-head">
          <span className="eyebrow">Fitur Inti</span>
          <h2>Dibangun untuk performa dan kenyamanan</h2>
          <p className="muted">Yang sudah tersedia hari ini, dan yang sedang kami kerjakan. Kami jujur soal statusnya.</p>
        </div>
        <div className="feature-grid">
          {features.map((f) => {
            const Icon = featureIcons[f.icon];
            return (
              <article key={f.title} className={`feature glass status-${f.status}`}>
                <div className="feature-top">
                  <span className="feature-icon"><Icon size={22} /></span>
                  <span className={`chip chip-${f.status === 'ready' ? 'ok' : f.status === 'beta' ? 'warn' : 'info'}`}>
                    {statusLabel[f.status]}
                  </span>
                </div>
                <h3>{f.title}</h3>
                <p className="muted">{f.body}</p>
                <span className="feature-tag">{f.tag}</span>
              </article>
            );
          })}
        </div>
      </section>

      {/* Specs */}
      <section id="spesifikasi" className="section container">
        <div className="section-head">
          <h2>Kebutuhan Sistem &amp; Spesifikasi</h2>
          <p className="muted">Berjalan baik di laptop hemat daya hingga PC gaming.</p>
        </div>
        <div className="spec-grid">
          {specs.map((s) => (
            <article key={s.platform} className="spec glass">
              <header>
                <span className="feature-icon">
                  {s.platform === 'windows' ? <IconWindows size={22} /> : <IconAndroid size={22} />}
                </span>
                <div>
                  <h3>{s.title}</h3>
                  <span className="muted small">{s.subtitle}</span>
                </div>
              </header>
              <dl>
                {s.rows.map((r) => (
                  <div key={r.label}>
                    <dt className="muted">{r.label}</dt>
                    <dd className={r.highlight ? 'hl' : undefined}>{r.value}</dd>
                  </div>
                ))}
              </dl>
            </article>
          ))}
        </div>
      </section>

      {/* Free vs Plus */}
      <section id="plus" className="section container narrow">
        <div className="section-head">
          <h2>Perbandingan Free &amp; Plus</h2>
          <p className="muted">Satu kunci Nuvio Plus berlaku untuk PC dan Android.</p>
        </div>
        <div className="compare glass">
          <table>
            <thead>
              <tr><th>Fitur</th><th>Free</th><th className="plus-col">Nuvio Plus</th></tr>
            </thead>
            <tbody>
              {compareRows.map((r) => (
                <tr key={r.label}>
                  <td>{r.label}</td>
                  <td className="muted">{r.free}</td>
                  <td className="plus-col">{r.plus}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <div className="center"><Link href="/plus" className="btn">Lihat Nuvio Plus</Link></div>
      </section>

      <ReviewsSection />
      <Faq />

      {/* Final CTA */}
      <section className="container section">
        <div className="cta glass">
          <h2>Siap bermain dengan gaya?</h2>
          <p className="muted">Unduh Nuvio Launcher gratis untuk Windows dan Android.</p>
          <DownloadCards release={release} compact />
        </div>
      </section>
    </>
  );
}
