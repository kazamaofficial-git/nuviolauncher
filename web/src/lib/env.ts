/**
 * Typed, lazily-read environment access. Values are read at call time so they are
 * never inlined into the client bundle (only NEXT_PUBLIC_* values are public).
 */
export const env = {
  siteUrl: () => (process.env.NEXT_PUBLIC_SITE_URL ?? 'http://localhost:3000').replace(/\/$/, ''),
  purchaseUrl: () => process.env.NEXT_PUBLIC_PURCHASE_URL ?? '',
  githubRepo: () => process.env.GITHUB_REPO ?? '',
  githubToken: () => process.env.GITHUB_TOKEN ?? '',
  adminEmail: () => (process.env.ADMIN_EMAIL ?? '').trim().toLowerCase(),
  adminPasswordHash: () => process.env.ADMIN_PASSWORD_HASH ?? '',
  googleClientId: () => process.env.GOOGLE_CLIENT_ID ?? '',
  googleClientSecret: () => process.env.GOOGLE_CLIENT_SECRET ?? '',
  smtpHost: () => process.env.SMTP_HOST ?? '',
  smtpPort: () => Number(process.env.SMTP_PORT ?? 587),
  smtpSecure: () => process.env.SMTP_SECURE === 'true',
  smtpUser: () => process.env.SMTP_USER ?? '',
  smtpPass: () => process.env.SMTP_PASS ?? '',
  smtpFrom: () => process.env.SMTP_FROM ?? 'Nuvio Launcher <no-reply@localhost>',
  texturesDir: () => process.env.TEXTURES_DIR ?? './data/textures',
  yggdrasilPrivateKey: () => (process.env.YGGDRASIL_PRIVATE_KEY ?? '').replace(/\\n/g, '\n'),
  yggdrasilKeyFile: () => process.env.YGGDRASIL_KEY_FILE ?? './data/yggdrasil-private.pem',
  sessionSecret: () => {
    const secret = process.env.SESSION_SECRET ?? '';
    if (secret.length >= 32) return secret;
    if (process.env.NODE_ENV === 'production') {
      throw new Error('SESSION_SECRET must be set to at least 32 characters.');
    }
    return 'dev-only-insecure-session-secret-change-me';
  },
};
