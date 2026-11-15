'use client';

import { useEffect, useRef } from 'react';

/** Draws the front of a skin (head, body, arms, legs) and optionally a cape back, pixel-perfect. */
export function SkinPreview({ skinUrl, capeUrl }: { skinUrl: string | null; capeUrl: string | null }) {
  const ref = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const canvas = ref.current;
    const ctx = canvas?.getContext('2d');
    if (!canvas || !ctx) return;
    ctx.imageSmoothingEnabled = false;
    const S = 8;
    const load = (src: string | null) =>
      new Promise<HTMLImageElement | null>((resolve) => {
        if (!src) return resolve(null);
        const img = new Image();
        img.crossOrigin = 'anonymous';
        img.onload = () => resolve(img);
        img.onerror = () => resolve(null);
        img.src = src;
      });

    let cancelled = false;
    void Promise.all([load(skinUrl), load(capeUrl)]).then(([skin, cape]) => {
      if (cancelled) return;
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      const px = (img: HTMLImageElement, sx: number, sy: number, w: number, h: number, dx: number, dy: number) =>
        ctx.drawImage(img, sx, sy, w, h, dx * S, dy * S, w * S, h * S);
      if (skin) {
        const legacy = skin.height === 32;
        px(skin, 8, 8, 8, 8, 4, 0); px(skin, 40, 8, 8, 8, 4, 0);      // head + hat
        px(skin, 20, 20, 8, 12, 4, 8);                                   // body
        px(skin, 44, 20, 4, 12, 0, 8);                                   // right arm
        px(skin, legacy ? 44 : 36, legacy ? 20 : 52, 4, 12, 12, 8);      // left arm
        px(skin, 4, 20, 4, 12, 4, 20);                                   // right leg
        px(skin, legacy ? 4 : 20, legacy ? 20 : 52, 4, 12, 8, 20);       // left leg
      }
      if (cape) {
        const k = cape.width / 64;
        ctx.drawImage(cape, 1 * k, 1 * k, 10 * k, 16 * k, 20 * S, 4 * S, 10 * S, 16 * S);
      }
    });
    return () => { cancelled = true; };
  }, [skinUrl, capeUrl]);

  return <canvas ref={ref} width={32 * 8} height={32 * 8} className="skin-canvas" aria-label="Pratinjau skin" />;
}
