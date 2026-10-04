/**
 * Membuat tangkapan layar untuk memeriksa tampilan game tanpa peramban.
 * Alat pengembangan saja (butuh @napi-rs/canvas):
 *
 *   cd web && npm i --no-save @napi-rs/canvas && npx tsx tools/shots.ts
 */

import { mkdirSync, writeFileSync } from 'node:fs';
import { createCanvas } from '@napi-rs/canvas';
import { village } from '../src/core/data';
import type { Ctx } from '../src/game/draw';
import { drawCharacter } from '../src/game/character';
import { drawGround } from '../src/game/ground';
import { alpha, C } from '../src/game/palette';
import { drawGlow, drawProp } from '../src/game/props';
import { drawDuskScene, drawNightScene } from '../src/game/scenery';

const OUT = '.shots';
mkdirSync(OUT, { recursive: true });

type Paint = (ctx: Ctx, w: number, h: number) => void;

function shot(name: string, w: number, h: number, paint: Paint): void {
  const canvas = createCanvas(w, h);
  const ctx = canvas.getContext('2d') as unknown as Ctx;
  // Kecerahan bawaan (Pengaturan → Kecerahan), supaya tangkapan sama dengan layar.
  ctx.filter = 'brightness(1.15)';
  paint(ctx, w, h);
  writeFileSync(`${OUT}/${name}.png`, canvas.toBuffer('image/png'));
  console.log(`  ${name}.png (${w}x${h})`);
}

/** Meniru cara engine.ts menggambar desa, supaya hasilnya sama. */
function paintVillage(ctx: Ctx, w: number, h: number, centerX: number, centerY: number, night: boolean): void {
  const scale = 1.6;
  ctx.fillStyle = C.grassDark;
  ctx.fillRect(0, 0, w, h);
  ctx.save();
  ctx.scale(scale, scale);
  ctx.translate(-(centerX - w / 2 / scale), -(centerY - h / 2 / scale));

  drawGround(ctx, village);

  interface Item {
    y: number;
    draw: () => void;
  }
  const items: Item[] = [];
  for (const prop of village.props) {
    if (Math.abs(prop.x - centerX) > 900 || Math.abs(prop.y - centerY) > 700) continue;
    items.push({
      y: prop.y,
      draw: () => {
        if (night && prop.glow > 0) drawGlow(ctx, prop.x, prop.y - prop.h * 0.8, prop.h * 2.6, C.lantern, prop.glow);
        ctx.save();
        ctx.translate(prop.x, prop.y);
        drawProp(ctx, { kind: prop.kind, w: prop.w, h: prop.h, variant: prop.variant, sway: prop.sway, glow: night ? prop.glow : 0 }, 3.2);
        ctx.restore();
      },
    });
  }
  for (const npc of village.npcs) {
    if (Math.abs(npc.x - centerX) > 900 || Math.abs(npc.y - centerY) > 700) continue;
    const gather = night && npc.gather_position ? npc.gather_position : { x: npc.x, y: npc.y };
    items.push({
      y: gather.y,
      draw: () =>
        drawCharacter(ctx, npc.palette_id, {
          x: gather.x,
          y: gather.y,
          facingX: 0,
          facingY: 1,
          speedRatio: night ? 0 : 0.4,
          phase: 1.4,
        }),
    });
  }
  items.push({
    y: centerY + 60,
    draw: () =>
      drawCharacter(ctx, 'raka', { x: centerX, y: centerY + 60, facingX: 0, facingY: 1, speedRatio: 0, phase: 0 }),
  });
  items.sort((a, b) => a.y - b.y);
  items.forEach((item) => item.draw());

  if (night) {
    ctx.fillStyle = alpha(C.nightSky, 0.18);
    ctx.fillRect(centerX - w, centerY - h, w * 2, h * 2);
  }
  ctx.restore();
}

console.log('membuat tangkapan layar:');
shot('menu_dusk', 1280, 720, (ctx, w, h) => drawDuskScene(ctx, w, h, 3.1, true));
shot('opening_dusk', 1280, 720, (ctx, w, h) => drawDuskScene(ctx, w, h, 8.4, true));
shot('village_gerbang', 1280, 720, (ctx, w, h) => paintVillage(ctx, w, h, 500, 1040, false));
shot('village_alun_alun', 1280, 720, (ctx, w, h) => paintVillage(ctx, w, h, 1490, 1010, false));
shot('village_malam', 1280, 720, (ctx, w, h) => paintVillage(ctx, w, h, 1490, 1010, true));
shot('ending_malam', 1280, 720, (ctx, w, h) =>
  drawNightScene(ctx, w, h, 6.2, [
    { palette: 'mbah_seno', x: 0.5, y: 0.585, facing: [0, 1] },
    { palette: 'sari', x: 0.41, y: 0.63, facing: [1, 0] },
    { palette: 'dimas', x: 0.59, y: 0.635, facing: [-1, 0] },
    { palette: 'bu_rini', x: 0.365, y: 0.7, facing: [1, 0] },
    { palette: 'pak_jaya', x: 0.63, y: 0.705, facing: [-1, 0] },
    { palette: 'warga_petani', x: 0.46, y: 0.74, facing: [0, -1] },
  ]),
);
console.log('selesai.');
