import { NextResponse } from 'next/server';
import { env } from '@/lib/env';
import { publicKeyPem } from '@/lib/yggdrasil';

export const dynamic = 'force-dynamic';

/** authlib-injector API metadata (the "API root"). */
export async function GET() {
  const host = new URL(env.siteUrl()).hostname;
  return NextResponse.json(
    {
      meta: {
        serverName: 'Nuvio',
        implementationName: 'nuvio-web',
        implementationVersion: '1.0.0',
        'feature.non_email_login': true,
      },
      skinDomains: [host],
      signaturePublickey: publicKeyPem(),
    },
    { headers: { 'Access-Control-Allow-Origin': '*' } },
  );
}
