'use client';

import { useEffect } from 'react';

/** After approval, bring the launcher to the foreground via the nuvio:// deep link. */
export function LinkRedirect() {
  useEffect(() => {
    const t = setTimeout(() => { window.location.href = 'nuvio://auth/success'; }, 800);
    return () => clearTimeout(t);
  }, []);
  return null;
}
