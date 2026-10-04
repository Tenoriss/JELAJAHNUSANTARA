/**
 * Gambar properti lingkungan (padanan Prop.gd versi Godot).
 *
 * Semua properti digambar dari bentuk dasar pada Canvas — tidak ada berkas
 * gambar. Origin setiap properti ada di titik dasarnya (menyentuh tanah).
 */

import { alpha, C, mix, shade } from './palette';
import { box, boxBorder, ellipse, line, poly, ring, roundRectPath, shadow, type Ctx } from './draw';

export interface PropView {
  kind: string;
  w: number;
  h: number;
  variant: number;
  sway: boolean;
  glow: number;
}

const ROOF_COLORS = [C.roofTile, C.terracotta, C.woodDark, C.roofShadow];
const WALL_COLORS = ['#e9d8ba', '#dcc9a6', '#b99a72', '#cbb491'];

export function drawProp(ctx: Ctx, prop: PropView, time: number): void {
  const { kind, w, h } = prop;
  const sway = prop.sway ? Math.sin(time * 1.1 + w * 0.01) * 1.6 : 0;
  switch (kind) {
    case 'house':
    case 'house_small':
      drawHouse(ctx, prop, w, h);
      break;
    case 'balai':
      drawBalai(ctx, prop, w, h);
      break;
    case 'workshop':
      drawWorkshop(ctx, prop, w, h);
      break;
    case 'saung':
      drawSaung(ctx, prop, w, h);
      break;
    case 'stage':
      drawStage(ctx, prop, w, h);
      break;
    case 'gapura':
      drawGapura(ctx, prop, w, h);
      break;
    case 'tree':
      drawTree(ctx, prop, w, h, sway);
      break;
    case 'palm':
      drawPalm(ctx, prop, w, h, sway);
      break;
    case 'bamboo_clump':
      drawBamboo(ctx, prop, w, h, sway);
      break;
    case 'well':
      drawWell(ctx, prop, w, h);
      break;
    case 'bench':
      drawBench(ctx, w, h);
      break;
    case 'lamp':
      drawLamp(ctx, prop, w, h, time);
      break;
    case 'table':
      drawTable(ctx, w, h);
      break;
    case 'crate':
      drawCrate(ctx, prop, w, h);
      break;
    case 'wood_stack':
      drawWoodStack(ctx, w, h);
      break;
    case 'tools':
      drawTools(ctx, w, h);
      break;
    case 'cart':
      drawCart(ctx, prop, w, h);
      break;
    case 'basket':
      drawBasket(ctx, w, h);
      break;
    case 'barrel':
      drawBarrel(ctx, prop, w, h);
      break;
    case 'rice_sheaf':
      drawRiceSheaf(ctx, w, h);
      break;
    case 'scarecrow':
      drawScarecrow(ctx, w, h);
      break;
    case 'flower_bush':
      drawFlowerBush(ctx, prop, w, h, sway);
      break;
    case 'grass_tuft':
      drawGrassTuft(ctx, w, h, sway);
      break;
    case 'rock':
      drawRock(ctx, prop, w, h);
      break;
    case 'lily':
      drawLily(ctx, w, h);
      break;
    case 'fence':
      drawFence(ctx, w, h);
      break;
    case 'banner':
      drawBanner(ctx, prop, w, h, sway);
      break;
    case 'fire_pit':
      drawFirePit(ctx, prop, w, h, time);
      break;
    case 'sign_post':
      drawSignPost(ctx, w, h);
      break;
    default:
      box(ctx, -w / 2, -h, w, h, C.wood, 4);
      break;
  }
}

/** Lingkaran cahaya untuk lampu yang menyala (digambar sebelum objek). */
export function drawGlow(ctx: Ctx, x: number, y: number, radius: number, color: string, strength: number): void {
  if (strength <= 0) return;
  const gradient = ctx.createRadialGradient(x, y, radius * 0.1, x, y, radius);
  gradient.addColorStop(0, alpha(color, 0.32 * strength));
  gradient.addColorStop(0.55, alpha(color, 0.12 * strength));
  gradient.addColorStop(1, alpha(color, 0));
  ctx.fillStyle = gradient;
  ctx.beginPath();
  ctx.arc(x, y, radius, 0, Math.PI * 2);
  ctx.fill();
}

// --- Bangunan --------------------------------------------------------------

function wallColor(variant: number): string {
  return WALL_COLORS[variant % WALL_COLORS.length];
}

function roofColor(variant: number): string {
  return ROOF_COLORS[variant % ROOF_COLORS.length];
}

function drawHouse(ctx: Ctx, prop: PropView, w: number, h: number): void {
  const wallHeight = h * 0.56;
  const roofHeight = h * 0.44;
  const left = -w / 2;
  const baseY = 0;
  shadow(ctx, 0, 0, w * 0.52, h * 0.1, 0.2);
  box(ctx, left, baseY - wallHeight, w, wallHeight, wallColor(prop.variant), 4);
  box(ctx, left, baseY - wallHeight * 0.18, w, wallHeight * 0.18, shade(wallColor(prop.variant), -0.12), 3);

  // atap
  poly(
    ctx,
    [
      [left - 14, baseY - wallHeight],
      [0, baseY - wallHeight - roofHeight],
      [-left + 14, baseY - wallHeight],
    ],
    roofColor(prop.variant),
  );
  poly(
    ctx,
    [
      [left - 14, baseY - wallHeight],
      [0, baseY - wallHeight - roofHeight],
      [0, baseY - wallHeight - roofHeight * 0.72],
      [left + 6, baseY - wallHeight - 2],
    ],
    shade(roofColor(prop.variant), -0.14),
  );

  // pintu & jendela
  const doorW = w * 0.22;
  const doorH = wallHeight * 0.6;
  box(ctx, -doorW / 2, baseY - doorH, doorW, doorH, C.woodDark, 3);
  box(ctx, -doorW / 2 + 3, baseY - doorH + 3, doorW - 6, doorH - 6, shade(C.wood, -0.1), 2);
  const windowW = w * 0.2;
  const windowH = wallHeight * 0.28;
  const windowY = baseY - wallHeight * 0.78;
  const lit = prop.glow > 0.05;
  if (lit) drawGlow(ctx, w * 0.28, windowY + windowH / 2, w * 0.5, C.lantern, prop.glow);
  boxBorder(
    ctx,
    w * 0.28 - windowW / 2,
    windowY,
    windowW,
    windowH,
    lit ? alpha(C.lantern, 0.92) : alpha(C.ink, 0.55),
    C.woodDark,
    2,
    3,
  );
}

function drawBalai(ctx: Ctx, prop: PropView, w: number, h: number): void {
  shadow(ctx, 0, 0, w * 0.5, h * 0.09, 0.22);
  const floorY = -h * 0.3;
  const pillarH = h * 0.3;
  // panggung & tiang
  box(ctx, -w * 0.42, floorY, w * 0.84, h * 0.1, C.wood, 3);
  for (const offset of [-w * 0.34, 0, w * 0.34]) {
    box(ctx, offset - 5, floorY + h * 0.1, 10, pillarH - h * 0.1, C.woodDark, 2);
  }
  // dinding terbuka belakang
  box(ctx, -w * 0.36, floorY - h * 0.34, w * 0.72, h * 0.34, mix(C.wood, C.cream, 0.35), 4);
  box(ctx, -w * 0.36, floorY - h * 0.34, w * 0.72, 6, C.woodDark, 2);
  // atap bertingkat
  poly(
    ctx,
    [
      [-w * 0.54, floorY - h * 0.34],
      [0, floorY - h * 0.72],
      [w * 0.54, floorY - h * 0.34],
    ],
    roofColor(prop.variant),
  );
  poly(
    ctx,
    [
      [-w * 0.4, floorY - h * 0.52],
      [0, floorY - h * 0.84],
      [w * 0.4, floorY - h * 0.52],
    ],
    shade(roofColor(prop.variant), 0.08),
  );
  // tulisan "BALAI DESA" kecil
  ctx.save();
  ctx.globalAlpha = 0.85;
  box(ctx, -34, floorY - h * 0.42, 68, 14, alpha(C.woodDark, 0.9), 4);
  ctx.restore();
}

function drawWorkshop(ctx: Ctx, prop: PropView, w: number, h: number): void {
  const wallHeight = h * 0.6;
  shadow(ctx, 0, 0, w * 0.5, h * 0.08, 0.2);
  box(ctx, -w / 2, -wallHeight, w, wallHeight, shade(C.woodLight, -0.12), 4);
  // sisi terbuka dengan rak
  box(ctx, -w * 0.34, -wallHeight * 0.86, w * 0.68, wallHeight * 0.72, alpha(C.inkSoft, 0.55), 3);
  line(ctx, -w * 0.34, -wallHeight * 0.5, w * 0.34, -wallHeight * 0.5, C.woodDark, 3);
  for (let i = 0; i < 3; i += 1) {
    box(ctx, -w * 0.28 + i * w * 0.22, -wallHeight * 0.62, w * 0.14, 10, C.wood, 2);
  }
  poly(
    ctx,
    [
      [-w / 2 - 12, -wallHeight],
      [0, -wallHeight - h * 0.4],
      [w / 2 + 12, -wallHeight],
    ],
    roofColor(prop.variant),
  );
  // papan nama
  box(ctx, -26, -wallHeight - h * 0.06, 52, 13, C.woodDark, 3);
}

function drawSaung(ctx: Ctx, _prop: PropView, w: number, h: number): void {
  shadow(ctx, 0, 0, w * 0.42, h * 0.08, 0.2);
  const floorY = -h * 0.34;
  for (const offset of [-w * 0.32, w * 0.32]) {
    box(ctx, offset - 4, floorY + h * 0.08, 8, h * 0.34 - h * 0.08, C.woodDark, 2);
  }
  box(ctx, -w * 0.42, floorY, w * 0.84, 8, C.wood, 3);
  // dinding anyaman
  box(ctx, -w * 0.38, floorY - h * 0.3, w * 0.76, h * 0.3, mix(C.bamboo, C.cream, 0.3), 3);
  poly(
    ctx,
    [
      [-w * 0.54, floorY - h * 0.3],
      [0, floorY - h * 0.62],
      [w * 0.54, floorY - h * 0.3],
    ],
    mix(C.woodLight, C.riceGold, 0.4),
  );
}

function drawStage(ctx: Ctx, prop: PropView, w: number, h: number): void {
  shadow(ctx, 0, 0, w * 0.5, h * 0.12, 0.22);
  // panggung kayu bertingkat
  box(ctx, -w / 2, -h * 0.34, w, h * 0.34, C.wood, 3);
  box(ctx, -w / 2, -h * 0.34, w, 8, C.woodLight, 3);
  box(ctx, -w * 0.4, -h * 0.16, w * 0.8, h * 0.16, shade(C.wood, -0.12), 3);
  // gapura panggung
  box(ctx, -w * 0.46, -h, 12, h * 0.68, C.woodDark, 3);
  box(ctx, w * 0.46 - 12, -h, 12, h * 0.68, C.woodDark, 3);
  box(ctx, -w * 0.5, -h - 12, w, 18, roofColor(prop.variant), 4);
  // hiasan kain di belakang
  box(ctx, -w * 0.3, -h * 0.92, w * 0.6, h * 0.5, alpha(C.indigo, 0.85), 4);
  if (prop.glow > 0.05) {
    drawGlow(ctx, 0, -h * 0.7, w * 0.55, C.lantern, prop.glow * 0.8);
  }
}

function drawGapura(ctx: Ctx, prop: PropView, w: number, h: number): void {
  const pillarW = w * 0.14;
  shadow(ctx, 0, 0, w * 0.5, h * 0.06, 0.18);
  for (const offset of [-w * 0.5 + pillarW / 2, w * 0.5 - pillarW / 2]) {
    box(ctx, offset - pillarW / 2, -h, pillarW, h, C.wood, 2);
    box(ctx, offset - pillarW / 2, -h * 0.72, pillarW, 10, C.woodDark, 2);
  }
  box(ctx, -w * 0.56, -h - 20, w * 1.12, 22, roofColor(prop.variant), 4);
  box(ctx, -w * 0.44, -h * 0.86, w * 0.88, 16, C.woodLight, 3);
  poly(
    ctx,
    [
      [-w * 0.6, -h - 20],
      [0, -h - 46],
      [w * 0.6, -h - 20],
    ],
    shade(roofColor(prop.variant), 0.06),
  );
  // ukiran sederhana
  ellipse(ctx, 0, -h * 0.86 + 8, 5, 5, alpha(C.gold, 0.9));
}

// --- Tumbuhan --------------------------------------------------------------

function drawTree(ctx: Ctx, _prop: PropView, w: number, h: number, sway: number): void {
  shadow(ctx, 0, 0, w * 0.34, h * 0.07, 0.22);
  const trunkH = h * 0.52;
  const tip = sway;
  line(ctx, 0, 0, tip * 0.4, -trunkH, C.woodDark, w * 0.13 + 3);
  line(ctx, 0, 0, tip * 0.4, -trunkH, C.wood, w * 0.13);
  ctx.save();
  ctx.translate(tip, -trunkH);
  const rx = w * 0.5;
  const ry = h * 0.3;
  ellipse(ctx, 0, -ry * 0.55, rx, ry, C.leafDark);
  ellipse(ctx, -rx * 0.45, -ry * 0.9, rx * 0.62, ry * 0.7, C.leaf);
  ellipse(ctx, rx * 0.42, -ry * 1.0, rx * 0.58, ry * 0.66, mix(C.leaf, C.leafLight, 0.5));
  ellipse(ctx, rx * 0.05, -ry * 1.35, rx * 0.52, ry * 0.6, C.leafLight);
  ctx.restore();
}

function drawPalm(ctx: Ctx, _prop: PropView, w: number, h: number, sway: number): void {
  shadow(ctx, 0, 0, w * 0.3, h * 0.05, 0.2);
  const trunkH = h * 0.78;
  for (let i = 0; i < 6; i += 1) {
    const t = i / 6;
    ellipse(ctx, sway * t * 1.4 + Math.sin(t * 3) * 2, -trunkH * t, w * 0.06 * (1 - t * 0.4), w * 0.06, i % 2 ? C.wood : C.woodDark);
  }
  ctx.save();
  ctx.translate(sway, -trunkH);
  for (let i = 0; i < 7; i += 1) {
    const angle = (i / 7) * Math.PI * 2 + 0.3;
    const length = w * 0.66;
    const ex = Math.cos(angle) * length;
    const ey = Math.sin(angle) * length * 0.5 - 5;
    line(ctx, 0, 0, ex, ey, i % 2 ? C.leaf : C.leafDark, 6);
  }
  ellipse(ctx, 0, 0, 5, 5, C.batikBrown);
  ctx.restore();
}

function drawBamboo(ctx: Ctx, _prop: PropView, w: number, h: number, sway: number): void {
  shadow(ctx, 0, 0, w * 0.3, h * 0.05, 0.18);
  const stalks = 5;
  for (let i = 0; i < stalks; i += 1) {
    const offset = (i - (stalks - 1) / 2) * (w / (stalks + 2));
    const height = h * (0.7 + (i % 3) * 0.12);
    const bend = sway * (0.6 + i * 0.12);
    const x = offset * 0.4;
    line(ctx, x, 0, x + bend, -height, C.bambooDark, 4.6);
    line(ctx, x, 0, x + bend, -height, C.bamboo, 3);
    for (let node = 1; node < 5; node += 1) {
      const ny = -height * (node / 5);
      const nx = x + bend * (node / 5);
      line(ctx, nx - 3, ny, nx + 3, ny, C.bambooDark, 2);
    }
    // daun
    for (let leaf = 0; leaf < 3; leaf += 1) {
      const ly = -height * (0.6 + leaf * 0.14);
      const lx = x + bend * (0.6 + leaf * 0.14);
      ellipse(ctx, lx + 6, ly, 8, 2.6, leaf % 2 ? C.leaf : C.leafDark);
      ellipse(ctx, lx - 6, ly + 4, 7, 2.4, C.leafLight);
    }
  }
}

function drawFlowerBush(ctx: Ctx, prop: PropView, w: number, h: number, sway: number): void {
  const colors = [C.rose, C.gold, C.goldPale, '#d3738a'];
  const tint = colors[prop.variant % colors.length];
  shadow(ctx, 0, 0, w * 0.4, h * 0.12, 0.16);
  ellipse(ctx, sway * 0.6, -h * 0.45, w * 0.5, h * 0.5, C.leafDark);
  ellipse(ctx, sway * 0.9 - w * 0.1, -h * 0.55, w * 0.34, h * 0.4, C.leaf);
  for (let i = 0; i < 5; i += 1) {
    const angle = (i / 5) * Math.PI * 2;
    ellipse(
      ctx,
      sway + Math.cos(angle) * w * 0.26,
      -h * 0.6 + Math.sin(angle) * h * 0.22,
      3.2,
      3.2,
      tint,
    );
  }
}

function drawGrassTuft(ctx: Ctx, w: number, h: number, sway: number): void {
  void sway;
  for (let i = -2; i <= 2; i += 1) {
    const x = i * (w / 5);
    line(ctx, x, 0, x + sway + i * 2.4, -h * (0.7 + (i % 2 === 0 ? 0.3 : 0.05)), C.grassDark, 2.6);
    line(ctx, x, 0, x + sway * 0.6 + i * 1.6, -h * 0.55, C.leafLight, 1.4);
  }
}

function drawRock(ctx: Ctx, prop: PropView, w: number, h: number): void {
  shadow(ctx, 0, 0, w * 0.42, h * 0.14, 0.2);
  const shade2 = prop.variant % 2 === 0 ? C.stoneDark : C.pathStone;
  poly(
    ctx,
    [
      [-w * 0.5, 0],
      [-w * 0.36, -h * 0.72],
      [-w * 0.05, -h],
      [w * 0.28, -h * 0.8],
      [w * 0.5, -h * 0.18],
      [w * 0.32, 0],
    ],
    C.stone,
  );
  poly(
    ctx,
    [
      [-w * 0.5, 0],
      [-w * 0.36, -h * 0.72],
      [-w * 0.05, -h],
      [-w * 0.1, -h * 0.3],
    ],
    shade2,
  );
}

function drawLily(ctx: Ctx, w: number, h: number): void {
  ellipse(ctx, 0, -h * 0.5, w * 0.5, h * 0.5, alpha(C.leaf, 0.95));
  ellipse(ctx, w * 0.1, -h * 0.62, w * 0.22, h * 0.28, alpha(C.rose, 0.9));
  ellipse(ctx, -w * 0.3, -h * 0.42, w * 0.26, h * 0.34, alpha(C.leafDark, 0.9));
}

// --- Benda kecil -----------------------------------------------------------

function drawWell(ctx: Ctx, prop: PropView, w: number, h: number): void {
  shadow(ctx, 0, 0, w * 0.5, h * 0.16, 0.22);
  const rimY = -h * 0.18;
  poly(
    ctx,
    [
      [-w * 0.5, 0],
      [-w * 0.44, rimY],
      [w * 0.44, rimY],
      [w * 0.5, 0],
    ],
    C.stone,
  );
  ellipse(ctx, 0, rimY, w * 0.44, h * 0.12, C.stoneDark);
  ellipse(ctx, 0, rimY - 1.5, w * 0.36, h * 0.09, C.waterDeep);
  // atap kecil
  line(ctx, -w * 0.34, rimY, -w * 0.34, -h * 0.92, C.woodDark, 4);
  line(ctx, w * 0.34, rimY, w * 0.34, -h * 0.92, C.woodDark, 4);
  poly(
    ctx,
    [
      [-w * 0.6, -h * 0.92],
      [0, -h * 1.16],
      [w * 0.6, -h * 0.92],
    ],
    roofColor(prop.variant),
  );
  line(ctx, -w * 0.34, -h * 0.88, w * 0.34, -h * 0.88, C.wood, 3);
  box(ctx, -6, -h * 0.86, 12, 12, C.woodDark, 2);
}

function drawBench(ctx: Ctx, w: number, h: number): void {
  shadow(ctx, 0, 0, w * 0.46, h * 0.16, 0.2);
  box(ctx, -w / 2, -h * 0.7, w, h * 0.22, C.woodLight, 3);
  box(ctx, -w * 0.38, -h, w * 0.76, h * 0.3, C.wood, 3);
  box(ctx, -w * 0.4, -h * 0.48, 6, h * 0.48, C.woodDark, 2);
  box(ctx, w * 0.4 - 6, -h * 0.48, 6, h * 0.48, C.woodDark, 2);
}

function drawLamp(ctx: Ctx, prop: PropView, w: number, h: number, time: number): void {
  shadow(ctx, 0, 0, w * 0.4, h * 0.06, 0.22);
  const flicker = 0.9 + Math.sin(time * 7 + prop.variant) * 0.06;
  const strength = prop.glow * flicker;
  const headY = -h * 0.96;
  if (strength > 0.02) drawGlow(ctx, 0, headY + 4, h * 0.65, C.lantern, strength);
  line(ctx, 0, 0, 0, headY, C.woodDark, 5);
  line(ctx, 0, 0, 0, headY, C.wood, 3);
  box(ctx, -w * 0.34, -h * 0.36, w * 0.68, 5, C.woodDark, 2);
  // kepala lampu
  ellipse(ctx, 0, headY + 2, w * 0.4, w * 0.34, strength > 0.02 ? alpha(C.lantern, 0.95) : alpha(C.creamDark, 0.85));
  poly(
    ctx,
    [
      [-w * 0.46, headY - 2],
      [0, headY - 16],
      [w * 0.46, headY - 2],
    ],
    C.woodDark,
  );
}

function drawTable(ctx: Ctx, w: number, h: number): void {
  shadow(ctx, 0, 0, w * 0.48, h * 0.2, 0.2);
  box(ctx, -w / 2, -h * 0.8, w, h * 0.26, C.woodLight, 3);
  box(ctx, -w * 0.42, -h * 0.54, 6, h * 0.54, C.woodDark, 2);
  box(ctx, w * 0.42 - 6, -h * 0.54, 6, h * 0.54, C.woodDark, 2);
  box(ctx, -w * 0.42, -h * 0.56, w * 0.84, 4, C.wood, 2);
}

function drawCrate(ctx: Ctx, prop: PropView, w: number, h: number): void {
  shadow(ctx, 0, 0, w * 0.46, h * 0.16, 0.2);
  const tint = prop.variant % 2 ? C.woodLight : C.wood;
  box(ctx, -w / 2, -h, w, h, tint, 3);
  line(ctx, -w / 2, -h, w / 2, 0, C.woodDark, 2);
  line(ctx, w / 2, -h, -w / 2, 0, C.woodDark, 2);
  boxBorder(ctx, -w / 2, -h, w, h, null, C.woodDark, 2, 3);
}

function drawWoodStack(ctx: Ctx, w: number, h: number): void {
  shadow(ctx, 0, 0, w * 0.5, h * 0.16, 0.18);
  for (let row = 0; row < 3; row += 1) {
    const count = 3;
    for (let i = 0; i < count; i += 1) {
      const cx = -w * 0.36 + (i + (row % 2) * 0.5) * (w * 0.36);
      const cy = -h * 0.12 - row * (h * 0.3);
      ellipse(ctx, cx, cy, w * 0.1, h * 0.14, C.woodDark);
      ellipse(ctx, cx, cy, w * 0.07, h * 0.1, C.woodLight);
    }
  }
}

function drawTools(ctx: Ctx, w: number, h: number): void {
  line(ctx, -w * 0.35, 0, -w * 0.1, -h, C.wood, 4);
  box(ctx, -w * 0.18, -h - 6, 12, 7, C.stoneDark, 2);
  line(ctx, w * 0.05, 0, w * 0.3, -h * 0.8, C.wood, 3);
  ring(ctx, w * 0.34, -h * 0.86, 6, 5, C.stone, 2.4, 12);
  box(ctx, -w * 0.5, -h * 0.3, w * 0.3, h * 0.3, C.batikBrown, 2);
}

function drawCart(ctx: Ctx, prop: PropView, w: number, h: number): void {
  shadow(ctx, 0, 0, w * 0.5, h * 0.18, 0.22);
  box(ctx, -w * 0.44, -h * 0.86, w * 0.88, h * 0.56, prop.variant % 2 ? C.wood : C.woodLight, 3);
  boxBorder(ctx, -w * 0.44, -h * 0.86, w * 0.88, h * 0.56, null, C.woodDark, 2, 3);
  for (const offset of [-w * 0.28, w * 0.28]) {
    ellipse(ctx, offset, -h * 0.18, w * 0.16, h * 0.18, C.woodDark);
    ellipse(ctx, offset, -h * 0.18, w * 0.05, h * 0.06, C.stone);
  }
  line(ctx, w * 0.42, -h * 0.7, w * 0.6, -h * 0.9, C.woodDark, 4);
}

function drawBasket(ctx: Ctx, w: number, h: number): void {
  shadow(ctx, 0, 0, w * 0.44, h * 0.18, 0.18);
  poly(
    ctx,
    [
      [-w * 0.36, 0],
      [w * 0.36, 0],
      [w * 0.5, -h * 0.8],
      [-w * 0.5, -h * 0.8],
    ],
    mix(C.bamboo, C.woodLight, 0.5),
  );
  for (let i = 1; i < 4; i += 1) {
    const y = -h * 0.2 * i;
    line(ctx, -w * 0.4, y, w * 0.4, y, alpha(C.woodDark, 0.6), 1.6);
  }
  ellipse(ctx, 0, -h * 0.8, w * 0.5, h * 0.14, C.woodDark);
}

function drawBarrel(ctx: Ctx, prop: PropView, w: number, h: number): void {
  shadow(ctx, 0, 0, w * 0.44, h * 0.16, 0.2);
  const tint = prop.variant % 2 ? C.wood : C.woodLight;
  roundRectPath(ctx, -w * 0.42, -h, w * 0.84, h, 8);
  ctx.fillStyle = tint;
  ctx.fill();
  for (const y of [-h * 0.82, -h * 0.5, -h * 0.18]) {
    box(ctx, -w * 0.44, y, w * 0.88, 5, C.stoneDark, 2);
  }
  ellipse(ctx, 0, -h, w * 0.42, h * 0.1, C.woodDark);
}

function drawRiceSheaf(ctx: Ctx, w: number, h: number): void {
  shadow(ctx, 0, 0, w * 0.4, h * 0.16, 0.16);
  for (let i = -1; i <= 1; i += 1) {
    line(ctx, 0, 0, i * w * 0.3, -h, C.riceGold, 3.4);
  }
  ellipse(ctx, 0, -h * 0.5, w * 0.36, h * 0.2, mix(C.riceGold, C.bamboo, 0.4));
  line(ctx, -w * 0.3, -h * 0.42, w * 0.3, -h * 0.5, alpha(C.woodDark, 0.7), 2.6);
}

function drawScarecrow(ctx: Ctx, w: number, h: number): void {
  shadow(ctx, 0, 0, w * 0.3, h * 0.1, 0.2);
  line(ctx, 0, 0, 0, -h * 0.92, C.woodDark, 5);
  line(ctx, -w * 0.5, -h * 0.66, w * 0.5, -h * 0.66, C.wood, 4);
  poly(
    ctx,
    [
      [-w * 0.42, -h * 0.62],
      [w * 0.42, -h * 0.62],
      [w * 0.3, -h * 0.24],
      [-w * 0.3, -h * 0.24],
    ],
    C.fabricYellow,
  );
  ellipse(ctx, 0, -h * 0.84, w * 0.22, h * 0.11, mix(C.riceGold, C.cream, 0.3));
  ellipse(ctx, 0, -h * 0.6, w * 0.1, h * 0.05, C.rose);
}

function drawFence(ctx: Ctx, w: number, h: number): void {
  const posts = 4;
  for (let i = 0; i < posts; i += 1) {
    const x = -w / 2 + (i / (posts - 1)) * w;
    box(ctx, x - 3, -h, 6, h, C.woodDark, 2);
  }
  box(ctx, -w / 2, -h * 0.78, w, 5, C.wood, 2);
  box(ctx, -w / 2, -h * 0.42, w, 5, C.wood, 2);
}

function drawBanner(ctx: Ctx, prop: PropView, w: number, h: number, sway: number): void {
  shadow(ctx, 0, 0, w * 0.4, h * 0.05, 0.2);
  line(ctx, 0, 0, 0, -h, C.woodDark, 5);
  const colors = [C.rose, C.gold, C.fabricBlue, C.indigo];
  const tint = colors[prop.variant % colors.length];
  const clothTop = -h * 0.96;
  const clothH = h * 0.6;
  poly(
    ctx,
    [
      [-w * 0.5 + sway * 0.4, clothTop],
      [w * 0.5 + sway, clothTop],
      [w * 0.5 + sway * 0.6, clothTop + clothH],
      [-w * 0.5 + sway * 0.2, clothTop + clothH],
    ],
    tint,
  );
  for (let i = 0; i < 3; i += 1) {
    const y = clothTop + clothH * (0.25 + i * 0.25);
    line(ctx, -w * 0.34 + sway * 0.3, y, w * 0.34 + sway * 0.6, y, alpha(C.cream, 0.5), 2);
  }
  ellipse(ctx, 0, -h - 3, w * 0.24, 5, C.gold);
}

function drawFirePit(ctx: Ctx, prop: PropView, w: number, h: number, time: number): void {
  shadow(ctx, 0, 0, w * 0.48, h * 0.2, 0.24);
  const flicker = 0.85 + Math.sin(time * 9) * 0.15 + Math.sin(time * 21.7) * 0.08;
  if (prop.glow > 0.02) drawGlow(ctx, 0, -h * 1.1, w * 1.5, C.fire, prop.glow * flicker);
  // batu
  for (let i = 0; i < 6; i += 1) {
    const angle = (i / 6) * Math.PI * 2;
    ellipse(ctx, Math.cos(angle) * w * 0.44, Math.sin(angle) * h * 0.3 - h * 0.1, 7, 5, i % 2 ? C.stone : C.stoneDark);
  }
  line(ctx, -w * 0.3, -h * 0.25, w * 0.28, -h * 0.4, C.woodDark, 5);
  line(ctx, -w * 0.28, -h * 0.42, w * 0.3, -h * 0.22, C.wood, 5);
  // api
  const flameH = h * (1.5 + flicker * 0.4);
  poly(
    ctx,
    [
      [-w * 0.12, -h * 0.3],
      [0, -h * 0.3 - flameH],
      [w * 0.12, -h * 0.3],
    ],
    alpha(C.fire, 0.9),
  );
  poly(
    ctx,
    [
      [-w * 0.06, -h * 0.3],
      [0, -h * 0.3 - flameH * 0.6],
      [w * 0.06, -h * 0.3],
    ],
    alpha(C.lantern, 0.95),
  );
}

function drawSignPost(ctx: Ctx, w: number, h: number): void {
  shadow(ctx, 0, 0, w * 0.34, h * 0.08, 0.2);
  line(ctx, 0, 0, 0, -h * 0.72, C.woodDark, 5);
  boxBorder(ctx, -w / 2, -h, w, h * 0.42, C.woodLight, C.woodDark, 2, 3);
  line(ctx, -w * 0.36, -h * 0.86, w * 0.36, -h * 0.86, alpha(C.woodDark, 0.7), 2);
  line(ctx, -w * 0.36, -h * 0.74, w * 0.2, -h * 0.74, alpha(C.woodDark, 0.7), 2);
}
