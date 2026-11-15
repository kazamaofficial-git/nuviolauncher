import { createHash } from 'node:crypto';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { env } from './env';

export type TextureKind = 'skin' | 'cape';

export const MAX_TEXTURE_BYTES = 256 * 1024;
const PNG_SIGNATURE = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);

/** Allowed pixel sizes. Skins: 64x64 / 64x32. Capes: 64x32, 22x17 and their HD multiples. */
const SIZES: Record<TextureKind, [number, number][]> = {
  skin: [[64, 64], [64, 32], [128, 128], [128, 64]],
  cape: [[64, 32], [22, 17], [46, 22], [128, 64], [92, 44]],
};

export class TextureError extends Error {}

/** Validates the PNG header + dimensions and stores it under its SHA-256. Returns the hash. */
export async function saveTexture(kind: TextureKind, data: Buffer): Promise<string> {
  if (data.length === 0 || data.length > MAX_TEXTURE_BYTES) {
    throw new TextureError('Ukuran berkas maksimal 256 KB.');
  }
  if (data.length < 33 || !data.subarray(0, 8).equals(PNG_SIGNATURE) || data.toString('ascii', 12, 16) !== 'IHDR') {
    throw new TextureError('Berkas harus berupa gambar PNG.');
  }
  const width = data.readUInt32BE(16);
  const height = data.readUInt32BE(20);
  if (!SIZES[kind].some(([w, h]) => w === width && h === height)) {
    const expected = SIZES[kind].map(([w, h]) => `${w}×${h}`).join(', ');
    throw new TextureError(`Ukuran ${width}×${height} tidak valid. Gunakan: ${expected}.`);
  }
  const hash = createHash('sha256').update(data).digest('hex');
  const dir = path.resolve(env.texturesDir());
  await mkdir(dir, { recursive: true });
  await writeFile(path.join(dir, `${hash}.png`), data);
  return hash;
}

export async function readTexture(hash: string): Promise<Buffer | null> {
  if (!/^[a-f0-9]{64}$/.test(hash)) return null;
  try {
    return await readFile(path.join(path.resolve(env.texturesDir()), `${hash}.png`));
  } catch {
    return null;
  }
}
