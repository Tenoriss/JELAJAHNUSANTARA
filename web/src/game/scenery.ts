/**
 * Latar sinematik (padanan Opening.gd dan Ending.gd versi Godot):
 * pemandangan senja di ujung desa, dan pemandangan malam di Lapangan Guyub.
 */

import { drawCharacter } from './character';
import { ellipse, line, poly, text, box, type Ctx } from './draw';
import { alpha, C, mix } from './palette';

function hash(seed: number): number {
  const value = Math.sin(seed * 78.233) * 43758.5453;
  return value - Math.floor(value);
}

/** Senja di jalan masuk desa — dipakai layar menu dan pembuka. */
export function drawDuskScene(ctx: Ctx, w: number, h: number, time: number, walking = false): void {
  const horizon = h * 0.66;

  // langit
  const bands: [string, number, number][] = [
    [C.duskHigh, 0, 0.3],
    [mix(C.duskHigh, C.duskSky, 0.55), 0.3, 0.22],
    [C.duskSky, 0.52, 0.16],
    [C.skyWarm, 0.68, 0.14],
  ];
  for (const [color, start, height] of bands) {
    ctx.fillStyle = color;
    ctx.fillRect(0, h * start, w, h * height + 1);
  }

  // matahari
  const sunX = w * 0.78;
  const sunY = horizon - 40;
  ellipse(ctx, sunX, sunY, w * 0.16, w * 0.16, alpha(C.goldPale, 0.1));
  ellipse(ctx, sunX, sunY, w * 0.09, w * 0.09, alpha(C.goldPale, 0.18));
  ellipse(ctx, sunX, sunY, w * 0.045, w * 0.045, alpha(C.lantern, 0.92));

  // bukit
  ellipse(ctx, w * 0.22, horizon + 28, w * 0.44, h * 0.26, alpha(C.leafDark, 0.5));
  ellipse(ctx, w * 0.8, horizon + 10, w * 0.42, h * 0.24, alpha(C.grassDark, 0.62));

  // sawah
  ctx.fillStyle = C.grassDark;
  ctx.fillRect(0, horizon, w, h - horizon);
  for (let i = 0; i < 7; i += 1) {
    const y = horizon + 20 + i * (h * 0.05);
    if (y > h) break;
    line(ctx, 0, y, w, y, alpha(C.riceGreen, 0.35), 3);
  }

  drawCottage(ctx, w * 0.26, horizon + 22, 0.72);
  drawCottage(ctx, w * 0.4, horizon + 34, 0.55);
  // pohon kelapa di kanan
  ellipse(ctx, w * 0.9, horizon - 16, w * 0.05, h * 0.07, C.leafDark);
  line(ctx, w * 0.9, horizon + 40, w * 0.9, horizon - 20, C.woodDark, 5);

  // jalan tanah menuju gapura
  poly(
    ctx,
    [
      [w * 0.42, horizon],
      [w * 0.58, horizon],
      [w * 0.72, h],
      [w * 0.28, h],
    ],
    alpha(C.pathSand, 0.92),
  );
  poly(
    ctx,
    [
      [w * 0.47, horizon],
      [w * 0.53, horizon],
      [w * 0.56, h],
      [w * 0.44, h],
    ],
    alpha(C.pathSandDark, 0.5),
  );

  // gapura desa
  const gateX = w * 0.5;
  const gateY = horizon - 4;
  const gateH = h * 0.28;
  box(ctx, gateX - w * 0.06, gateY - gateH, w * 0.022, gateH, C.wood, 3);
  box(ctx, gateX + w * 0.04, gateY - gateH, w * 0.022, gateH, C.wood, 3);
  poly(
    ctx,
    [
      [gateX - w * 0.08, gateY - gateH],
      [gateX, gateY - gateH - h * 0.07],
      [gateX + w * 0.08, gateY - gateH],
    ],
    C.roofTile,
  );
  box(ctx, gateX - w * 0.055, gateY - gateH + h * 0.03, w * 0.11, h * 0.042, C.woodLight, 4);
  text(ctx, 'DESA ARUNIKA', gateX, gateY - gateH + h * 0.03 + h * 0.03, Math.max(12, w * 0.011), C.ink, 'center', 'bold');

  // Raka di jalan
  drawCharacter(ctx, 'raka', {
    x: gateX + (walking ? Math.sin(time * 0.9) * 6 : 0),
    y: h * 0.86,
    facingX: 0,
    facingY: -1,
    speedRatio: walking ? 0.45 : 0.1,
    phase: time * (walking ? 4.4 : 1.2),
  });
}

function drawCottage(ctx: Ctx, x: number, baseY: number, scale: number): void {
  const width = 150 * scale;
  const wall = 74 * scale;
  box(ctx, x - width / 2, baseY - wall, width, wall, C.woodDark, 3);
  poly(
    ctx,
    [
      [x - width / 2 - 12 * scale, baseY - wall],
      [x, baseY - wall - 48 * scale],
      [x + width / 2 + 12 * scale, baseY - wall],
    ],
    C.roofTile,
  );
  box(ctx, x - 12 * scale, baseY - wall * 0.62, 24 * scale, 20 * scale, alpha(C.lantern, 0.6), 2);
}

export interface NightVillager {
  palette: string;
  x: number;
  y: number;
  facing: [number, number];
}

/** Malam di Lapangan Guyub — dipakai adegan penutup. */
export function drawNightScene(ctx: Ctx, w: number, h: number, time: number, villagers: NightVillager[]): void {
  ctx.fillStyle = C.nightSky;
  ctx.fillRect(0, 0, w, h);

  // bintang
  for (let i = 0; i < 70; i += 1) {
    const x = hash(i) * w;
    const y = hash(i + 99) * h * 0.5;
    const twinkle = 0.35 + 0.65 * Math.abs(Math.sin(time * 0.6 + i));
    ellipse(ctx, x, y, 1.4, 1.4, alpha(C.cream, twinkle * 0.8));
  }
  // bulan
  ellipse(ctx, w * 0.82, h * 0.16, h * 0.055, h * 0.055, alpha(C.cream, 0.9));
  ellipse(ctx, w * 0.82 - h * 0.02, h * 0.16 - h * 0.012, h * 0.05, h * 0.05, C.nightSky);

  const horizon = h * 0.62;
  ctx.fillStyle = mix(C.grassDark, C.nightSky, 0.55);
  ctx.fillRect(0, horizon, w, h - horizon);

  // gapura panggung
  const stageX = w * 0.5;
  box(ctx, stageX - w * 0.16, horizon - h * 0.22, w * 0.012, h * 0.22, C.woodDark, 2);
  box(ctx, stageX + w * 0.15, horizon - h * 0.22, w * 0.012, h * 0.22, C.woodDark, 2);
  box(ctx, stageX - w * 0.18, horizon - h * 0.25, w * 0.36, h * 0.035, C.roofShadow, 3);
  box(ctx, stageX - w * 0.12, horizon - h * 0.18, w * 0.24, h * 0.12, alpha(C.indigo, 0.9), 4);

  // lampu-lampu
  for (const offset of [-0.34, -0.18, 0.18, 0.34]) {
    const x = stageX + w * offset;
    line(ctx, x, horizon + 10, x, horizon - h * 0.11, C.woodDark, 3);
    ellipse(ctx, x, horizon - h * 0.12, 7, 8, alpha(C.lantern, 0.95));
    ellipse(ctx, x, horizon - h * 0.12, 26, 26, alpha(C.lantern, 0.16));
  }

  // api unggun
  const fireX = stageX;
  const fireY = horizon + h * 0.2;
  ellipse(ctx, fireX, fireY + 6, 46, 14, alpha(C.lantern, 0.12));
  ellipse(ctx, fireX, fireY, 30, 10, alpha(C.fire, 0.2));
  for (let i = 0; i < 6; i += 1) {
    const angle = (i / 6) * Math.PI * 2;
    ellipse(ctx, fireX + Math.cos(angle) * 30, fireY + Math.sin(angle) * 10, 7, 5, i % 2 ? C.stone : C.stoneDark);
  }
  const flame = 34 + Math.sin(time * 9) * 6;
  poly(
    ctx,
    [
      [fireX - 12, fireY - 4],
      [fireX, fireY - flame],
      [fireX + 12, fireY - 4],
    ],
    alpha(C.fire, 0.92),
  );
  poly(
    ctx,
    [
      [fireX - 6, fireY - 4],
      [fireX, fireY - flame * 0.6],
      [fireX + 6, fireY - 4],
    ],
    alpha(C.lantern, 0.95),
  );

  // warga
  for (const villager of villagers) {
    drawCharacter(ctx, villager.palette, {
      x: w * villager.x,
      y: h * villager.y,
      facingX: villager.facing[0],
      facingY: villager.facing[1],
      speedRatio: 0.08,
      phase: time * 1.1 + villager.x * 10,
    });
  }
}
