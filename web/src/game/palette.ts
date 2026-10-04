/**
 * Warna permainan.
 *
 * Nilai di bawah sama dengan scripts/util/Palette.gd pada versi Godot supaya
 * kedua versi terlihat satu keluarga (lihat tools/gen_village.py untuk peta).
 */

export const C = {
  cream: '#f6ead6',
  creamDim: '#dfcdae',
  creamDark: '#c4ae8c',
  ink: '#2b2118',
  inkSoft: '#3e3227',
  gold: '#f2b134',
  goldDeep: '#c98a22',
  goldPale: '#f7d68a',
  terracotta: '#b5543f',
  terracottaDark: '#8c3b2e',
  roofTile: '#a84a38',
  roofShadow: '#7d3427',
  wood: '#8b5a2b',
  woodDark: '#6b4423',
  woodLight: '#b07a45',
  bamboo: '#9ba84a',
  bambooDark: '#7c8838',
  leafDark: '#3f6b33',
  leaf: '#6f9a4b',
  leafLight: '#96be64',
  grass: '#7cab55',
  grassDark: '#63893f',
  grassLight: '#8cb264',
  soil: '#7a5a38',
  soilDark: '#5a4029',
  pathSand: '#d9b47c',
  pathSandDark: '#be9a66',
  pathStone: '#a9a296',
  water: '#5fa8c7',
  waterDeep: '#3f7f9e',
  paddyWater: '#7fbfa8',
  riceGreen: '#a8c96a',
  riceGold: '#d8c46a',
  stone: '#9aa0a6',
  stoneDark: '#767c82',
  indigo: '#2f4858',
  batikBrown: '#6b4f2a',
  rose: '#c25a6c',
  plum: '#6b3a5b',
  nightSky: '#27364a',
  duskSky: '#eb9a58',
  duskHigh: '#7b699e',
  lantern: '#ffc96b',
  fire: '#ff8a3d',
  skyDay: '#a8d6e9',
  skyWarm: '#f7deb1',
  skinLight: '#e0b183',
  skin: '#c98a5b',
  skinDark: '#a46b45',
  hairDark: '#241a12',
  hairGrey: '#d8d3c8',
  fabricBlue: '#3e7c8f',
  fabricGreen: '#4e6b4a',
  fabricRed: '#b23a57',
  fabricYellow: '#e8b04b',
  hint: '#8fd5a6',
  danger: '#e0644d',
  shadow: 'rgba(13,10,8,0.2)',
  dim: 'rgba(8,5,4,0.76)',
} as const;

export type PaletteKey = keyof typeof C;

/** Ubah "#rrggbb" + alpha menjadi rgba(). */
export function alpha(color: string, a: number): string {
  const hex = color.replace('#', '');
  if (hex.length !== 6) return color;
  const r = parseInt(hex.slice(0, 2), 16);
  const g = parseInt(hex.slice(2, 4), 16);
  const b = parseInt(hex.slice(4, 6), 16);
  return `rgba(${r},${g},${b},${a})`;
}

export function mix(a: string, b: string, t: number): string {
  const pa = parse(a);
  const pb = parse(b);
  const lerp = (x: number, y: number) => Math.round(x + (y - x) * t);
  return `#${toHex(lerp(pa[0], pb[0]))}${toHex(lerp(pa[1], pb[1]))}${toHex(lerp(pa[2], pb[2]))}`;
}

export function shade(color: string, amount: number): string {
  const [r, g, b] = parse(color);
  const target = amount >= 0 ? 255 : 0;
  const t = Math.abs(amount);
  const lerp = (v: number) => Math.round(v + (target - v) * t);
  return `#${toHex(lerp(r))}${toHex(lerp(g))}${toHex(lerp(b))}`;
}

function parse(color: string): [number, number, number] {
  const hex = color.replace('#', '');
  return [
    parseInt(hex.slice(0, 2), 16),
    parseInt(hex.slice(2, 4), 16),
    parseInt(hex.slice(4, 6), 16),
  ];
}

function toHex(value: number): string {
  return Math.max(0, Math.min(255, value)).toString(16).padStart(2, '0');
}

export interface CharacterPalette {
  skin: string;
  hair: string;
  shirt: string;
  shirtDark: string;
  lower: string;
  shoes: string;
  accent: string;
  style: 'young' | 'elder' | 'woman' | 'craftsman' | 'youth' | 'child';
  hat: '' | 'straw' | 'cap';
  bun: boolean;
  skirt: boolean;
  scarf: boolean;
  scale: number;
}

export const CHARACTERS: Record<string, CharacterPalette> = {
  raka: {
    skin: C.skin,
    hair: C.hairDark,
    shirt: C.fabricBlue,
    shirtDark: '#2b5968',
    lower: '#454f5c',
    shoes: C.woodDark,
    accent: C.gold,
    style: 'young',
    hat: '',
    bun: false,
    skirt: false,
    scarf: false,
    scale: 1,
  },
  mbah_seno: {
    skin: C.skinDark,
    hair: C.hairGrey,
    shirt: C.batikBrown,
    shirtDark: '#4c381f',
    lower: '#38383d',
    shoes: C.woodDark,
    accent: C.indigo,
    style: 'elder',
    hat: 'straw',
    bun: false,
    skirt: false,
    scarf: true,
    scale: 0.97,
  },
  sari: {
    skin: C.skin,
    hair: C.hairDark,
    shirt: C.fabricRed,
    shirtDark: '#82263d',
    lower: C.batikBrown,
    shoes: C.woodDark,
    accent: C.gold,
    style: 'woman',
    hat: '',
    bun: true,
    skirt: true,
    scarf: false,
    scale: 0.95,
  },
  pak_jaya: {
    skin: C.skin,
    hair: '#33291f',
    shirt: C.fabricGreen,
    shirtDark: '#395133',
    lower: '#3d454f',
    shoes: C.woodDark,
    accent: C.woodLight,
    style: 'craftsman',
    hat: '',
    bun: false,
    skirt: false,
    scarf: false,
    scale: 1.02,
  },
  bu_rini: {
    skin: C.skin,
    hair: C.hairDark,
    shirt: C.fabricBlue,
    shirtDark: '#2b5968',
    lower: C.batikBrown,
    shoes: C.woodDark,
    accent: C.rose,
    style: 'woman',
    hat: '',
    bun: true,
    skirt: true,
    scarf: false,
    scale: 0.95,
  },
  dimas: {
    skin: C.skin,
    hair: C.hairDark,
    shirt: '#4f5c8c',
    shirtDark: '#363f66',
    lower: '#383f54',
    shoes: C.fabricRed,
    accent: C.fabricRed,
    style: 'youth',
    hat: 'cap',
    bun: false,
    skirt: false,
    scarf: false,
    scale: 1,
  },
  warga_petani: {
    skin: C.skinDark,
    hair: C.hairDark,
    shirt: C.fabricYellow,
    shirtDark: '#b88733',
    lower: '#404047',
    shoes: C.woodDark,
    accent: C.leafDark,
    style: 'elder',
    hat: 'straw',
    bun: false,
    skirt: false,
    scarf: false,
    scale: 0.99,
  },
  warga_penjual: {
    skin: C.skin,
    hair: C.hairDark,
    shirt: C.rose,
    shirtDark: '#8c3d4d',
    lower: C.batikBrown,
    shoes: C.woodDark,
    accent: C.gold,
    style: 'woman',
    hat: '',
    bun: true,
    skirt: true,
    scarf: false,
    scale: 0.94,
  },
  warga_anak: {
    skin: C.skinLight,
    hair: C.hairDark,
    shirt: C.leafLight,
    shirtDark: '#70944c',
    lower: C.fabricBlue,
    shoes: C.fabricRed,
    accent: C.gold,
    style: 'child',
    hat: '',
    bun: false,
    skirt: false,
    scarf: false,
    scale: 0.78,
  },
};

export function character(id: string): CharacterPalette {
  return CHARACTERS[id] ?? CHARACTERS.raka;
}

export const MOTIF_COLORS: Record<string, string> = {
  kawung: C.indigo,
  ceplok: C.batikBrown,
  tumpal: C.gold,
  parang: '#c25a6c',
};
