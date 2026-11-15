import Image from 'next/image';

/** Hero logo with glow and two slowly rotating orbital rings. */
export function OrbitalLogo({ size = 440 }: { size?: number }) {
  return (
    <div className="orbital" style={{ width: size, height: size }}>
      <span className="orbital-glow" />
      <svg className="ring ring-a" viewBox="0 0 200 200" aria-hidden="true">
        <ellipse cx="100" cy="100" rx="94" ry="34" />
      </svg>
      <svg className="ring ring-b" viewBox="0 0 200 200" aria-hidden="true">
        <ellipse cx="100" cy="100" rx="94" ry="34" />
      </svg>
      <Image
        className="orbital-mark"
        src="/brand/nuvio-mark.png"
        alt="Logo Nuvio Launcher"
        width={900}
        height={594}
        priority
        sizes="(max-width: 700px) 70vw, 440px"
      />
    </div>
  );
}
