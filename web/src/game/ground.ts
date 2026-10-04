/**
 * Gambar tanah Desa Arunika (padanan VillageGround.gd versi Godot).
 *
 * Tanah digambar sekali per frame dari bentuk dasar: rumput, jalan tanah,
 * alun-alun, pematang sawah, kolam, kebun, dan hamparan bunga.
 */

import type { Rect } from '../core/types';
import type { VillageData } from '../core/villageTypes';
import { alpha, C, mix } from './palette';
import { box, ellipse, line, roundRectPath, type Ctx } from './draw';

/** Angka acak yang selalu sama untuk posisi tertentu (agar bunga tidak berkedip). */
function hash(seed: number): number {
  const value = Math.sin(seed * 12.9898) * 43758.5453;
  return value - Math.floor(value);
}

export function drawGround(ctx: Ctx, world: VillageData): void {
  const { map } = world;
  ctx.fillStyle = C.grass;
  ctx.fillRect(map.x, map.y, map.w, map.h);

  // Gelombang rumput tipis supaya tanah tidak terlihat rata.
  const bands = 26;
  for (let i = 0; i < bands; i += 1) {
    const y = map.y + (i / bands) * map.h;
    const tint = i % 2 === 0 ? C.grassDark : C.grassLight;
    ctx.fillStyle = alpha(tint, 0.16);
    ctx.fillRect(map.x, y, map.w, map.h / bands * 0.6);
  }

  world.open_soil.forEach((rect) => soilPatch(ctx, rect));
  world.gardens.forEach((rect) => garden(ctx, rect));
  world.flowers.forEach((rect, index) => flowerPatch(ctx, rect, index));
  world.paddies.forEach((rect) => paddy(ctx, rect));
  world.ponds.forEach((rect) => pond(ctx, rect));
  world.paths.forEach((rect) => path(ctx, rect));
  world.plazas.forEach((rect) => plaza(ctx, rect));
}

function path(ctx: Ctx, rect: Rect): void {
  roundRectPath(ctx, rect.x, rect.y, rect.w, rect.h, Math.min(rect.w, rect.h) * 0.45);
  ctx.fillStyle = C.pathSand;
  ctx.fill();
  ctx.strokeStyle = alpha(C.pathSandDark, 0.75);
  ctx.lineWidth = 2;
  ctx.stroke();
}

function plaza(ctx: Ctx, rect: Rect): void {
  roundRectPath(ctx, rect.x, rect.y, rect.w, rect.h, 26);
  ctx.fillStyle = C.pathSand;
  ctx.fill();
  ctx.strokeStyle = alpha(C.pathSandDark, 0.85);
  ctx.lineWidth = 3;
  ctx.stroke();
  // pola batu ringan di tengah
  const cx = rect.x + rect.w / 2;
  const cy = rect.y + rect.h / 2;
  for (let i = 1; i <= 3; i += 1) {
    ctx.strokeStyle = alpha(C.pathSandDark, 0.35);
    ctx.lineWidth = 1.6;
    ctx.beginPath();
    ctx.ellipse(cx, cy, (rect.w * 0.16) * i, (rect.h * 0.16) * i, 0, 0, Math.PI * 2);
    ctx.stroke();
  }
}

function soilPatch(ctx: Ctx, rect: Rect): void {
  roundRectPath(ctx, rect.x, rect.y, rect.w, rect.h, 18);
  ctx.fillStyle = C.soil;
  ctx.fill();
  ctx.strokeStyle = alpha(C.soilDark, 0.7);
  ctx.lineWidth = 2;
  ctx.stroke();
}

function garden(ctx: Ctx, rect: Rect): void {
  soilPatch(ctx, rect);
  const rows = 4;
  for (let i = 0; i < rows; i += 1) {
    const y = rect.y + ((i + 0.5) / rows) * rect.h;
    box(ctx, rect.x + 8, y - 3, rect.w - 16, 6, C.soilDark, 3);
    for (let j = 0; j < 4; j += 1) {
      const x = rect.x + 16 + (j / 3) * (rect.w - 32);
      ellipse(ctx, x, y - 6, 4.4, 5, C.leaf);
      ellipse(ctx, x, y - 8, 2.6, 3, C.leafLight);
    }
  }
}

function paddy(ctx: Ctx, rect: Rect): void {
  roundRectPath(ctx, rect.x, rect.y, rect.w, rect.h, 12);
  ctx.fillStyle = C.paddyWater;
  ctx.fill();
  ctx.strokeStyle = C.pathSandDark;
  ctx.lineWidth = 4;
  ctx.stroke();
  // baris padi
  const rows = Math.max(3, Math.floor(rect.h / 46));
  for (let i = 0; i < rows; i += 1) {
    const y = rect.y + 22 + (i / (rows - 1)) * (rect.h - 42);
    line(ctx, rect.x + 10, y, rect.x + rect.w - 10, y, alpha(C.riceGreen, 0.9), 3);
    const stalks = Math.max(2, Math.floor(rect.w / 60));
    for (let j = 0; j < stalks; j += 1) {
      const x = rect.x + 16 + (j / Math.max(1, stalks - 1)) * (rect.w - 32);
      line(ctx, x, y, x - 3, y - 12, alpha(C.riceGreen, 0.85), 2);
      line(ctx, x, y, x + 3, y - 10, alpha(C.leafLight, 0.75), 1.6);
    }
  }
}

function pond(ctx: Ctx, rect: Rect): void {
  ellipse(ctx, rect.x + rect.w / 2, rect.y + rect.h / 2, rect.w / 2, rect.h / 2, C.pathSandDark);
  ellipse(ctx, rect.x + rect.w / 2, rect.y + rect.h / 2, rect.w / 2 - 4, rect.h / 2 - 4, C.water);
  ellipse(ctx, rect.x + rect.w * 0.35, rect.y + rect.h * 0.42, rect.w * 0.16, rect.h * 0.12, alpha(C.waterDeep, 0.6));
  for (let i = 0; i < 3; i += 1) {
    const x = rect.x + rect.w * (0.25 + i * 0.25);
    const y = rect.y + rect.h * (0.3 + (i % 2) * 0.4);
    ellipse(ctx, x, y, 7, 4.4, alpha(C.leaf, 0.95));
  }
}

function flowerPatch(ctx: Ctx, rect: Rect, index: number): void {
  const colors = [C.goldPale, C.rose, C.gold, C.cream];
  ctx.fillStyle = alpha(C.leaf, 0.35);
  roundRectPath(ctx, rect.x, rect.y, rect.w, rect.h, 40);
  ctx.fill();
  const count = 16;
  for (let i = 0; i < count; i += 1) {
    const seed = index * 37 + i * 11;
    const x = rect.x + hash(seed) * rect.w;
    const y = rect.y + hash(seed + 5) * rect.h;
    const color = colors[(index + i) % colors.length];
    ellipse(ctx, x, y, 2.6, 2.6, mix(color, C.leaf, 0.1));
    ellipse(ctx, x + 3, y + 2, 5, 2, alpha(C.leafDark, 0.5));
  }
}
