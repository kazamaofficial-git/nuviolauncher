import type { SVGProps } from 'react';

type IconProps = SVGProps<SVGSVGElement> & { size?: number };

function Svg({ size = 20, children, ...rest }: IconProps) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.8"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
      {...rest}
    >
      {children}
    </svg>
  );
}

export const IconBolt = (p: IconProps) => (
  <Svg {...p}><path d="M13 2 4 14h7l-1 8 9-12h-7l1-8Z" /></Svg>
);
export const IconBox = (p: IconProps) => (
  <Svg {...p}><path d="m21 8-9-5-9 5 9 5 9-5Z" /><path d="M3 8v8l9 5 9-5V8" /><path d="M12 13v8" /></Svg>
);
export const IconKey = (p: IconProps) => (
  <Svg {...p}><circle cx="8" cy="15" r="4" /><path d="m11 12 9-9" /><path d="m16 7 3 3" /></Svg>
);
export const IconOrbit = (p: IconProps) => (
  <Svg {...p}><circle cx="12" cy="12" r="2.5" /><ellipse cx="12" cy="12" rx="10" ry="4" transform="rotate(-30 12 12)" /></Svg>
);
export const IconPuzzle = (p: IconProps) => (
  <Svg {...p}><path d="M10 3a2 2 0 0 1 4 0v2h4v4h2a2 2 0 0 1 0 4h-2v6H4v-6h2a2 2 0 0 0 0-4H4V5h6V3Z" /></Svg>
);
export const IconUser = (p: IconProps) => (
  <Svg {...p}><circle cx="12" cy="8" r="4" /><path d="M4 21c0-4 4-6 8-6s8 2 8 6" /></Svg>
);
export const IconServer = (p: IconProps) => (
  <Svg {...p}><rect x="3" y="4" width="18" height="7" rx="2" /><rect x="3" y="13" width="18" height="7" rx="2" /><path d="M7 7.5h.01M7 16.5h.01" /></Svg>
);
export const IconPhone = (p: IconProps) => (
  <Svg {...p}><rect x="2" y="7" width="20" height="10" rx="2" /><path d="M18.5 12h.01" /></Svg>
);
export const IconDownload = (p: IconProps) => (
  <Svg {...p}><path d="M12 3v12" /><path d="m7 11 5 5 5-5" /><path d="M5 21h14" /></Svg>
);
export const IconCheck = (p: IconProps) => (
  <Svg {...p}><path d="m5 12 5 5 9-10" /></Svg>
);
export const IconStar = (p: IconProps) => (
  <Svg {...p} fill="currentColor" stroke="none"><path d="m12 2.5 2.9 6 6.6.9-4.8 4.6 1.2 6.5L12 17.4 6.1 20.5l1.2-6.5L2.5 9.4l6.6-.9L12 2.5Z" /></Svg>
);
export const IconWindows = (p: IconProps) => (
  <Svg {...p} fill="currentColor" stroke="none"><path d="M3 5.6 10.5 4.5v6.9H3V5.6Zm8.5-1.2L21 3v8.4h-9.5V4.4ZM3 12.6h7.5v6.9L3 18.4v-5.8Zm8.5 0H21V21l-9.5-1.4v-7Z" /></Svg>
);
export const IconAndroid = (p: IconProps) => (
  <Svg {...p} fill="currentColor" stroke="none"><path d="M6 9h12v8a1.5 1.5 0 0 1-1.5 1.5H15V21a1 1 0 0 1-2 0v-2.5h-2V21a1 1 0 0 1-2 0v-2.5H7.5A1.5 1.5 0 0 1 6 17V9Zm-3 .5a1 1 0 0 1 2 0v5a1 1 0 0 1-2 0v-5Zm16 0a1 1 0 0 1 2 0v5a1 1 0 0 1-2 0v-5ZM8.2 3.3l1 1.5A5 5 0 0 1 12 4a5 5 0 0 1 2.8.8l1-1.5.8.5-.9 1.4A5 5 0 0 1 17.6 8H6.4a5 5 0 0 1 1.9-2.3l-.9-1.4.8-.5ZM10 6.2a.6.6 0 1 0 0 1.2.6.6 0 0 0 0-1.2Zm4 0a.6.6 0 1 0 0 1.2.6.6 0 0 0 0-1.2Z" /></Svg>
);
export const IconShield = (p: IconProps) => (
  <Svg {...p}><path d="M12 3 4 6v6c0 5 3.5 8 8 9 4.5-1 8-4 8-9V6l-8-3Z" /><path d="m9 12 2 2 4-4" /></Svg>
);

export const featureIcons = {
  bolt: IconBolt,
  box: IconBox,
  key: IconKey,
  orbit: IconOrbit,
  puzzle: IconPuzzle,
  user: IconUser,
  server: IconServer,
  phone: IconPhone,
} as const;
