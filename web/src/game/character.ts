/**
 * Gambar karakter prosedural (padanan CharacterVisual.gd versi Godot).
 *
 * Origin berada di telapak kaki supaya urutan gambar atas-bawah (y-sort)
 * otomatis benar. Tidak memakai sprite: semua digambar dari bentuk dasar.
 */

import { alpha, character, C, type CharacterPalette } from './palette';
import { box, ellipse, line, poly, ring, shadow, type Ctx } from './draw';

const BODY_HEIGHT = 46;

export interface CharacterPose {
  x: number;
  y: number;
  /** Arah hadap: (0,1) bawah, (0,-1) atas, (1,0) kanan, (-1,0) kiri. */
  facingX: number;
  facingY: number;
  /** 0 = diam, 1 = langkah penuh. */
  speedRatio: number;
  /** Fase langkah (detik berjalan). */
  phase: number;
}

function easeSwing(phase: number): number {
  return Math.sin(phase * 7.4);
}

export function drawCharacter(ctx: Ctx, paletteId: string, pose: CharacterPose): void {
  const palette = character(paletteId);
  const s = palette.scale;
  const walk = pose.speedRatio;
  const bob = Math.abs(easeSwing(pose.phase)) * 1.9 * walk;
  const squash = 1 + Math.sin(pose.phase * 7.4 * 2) * 0.03 * walk;
  const back = pose.facingY < -0.4; // menghadap atas = punggung terlihat
  const side = Math.abs(pose.facingX) > 0.5;
  const dir = pose.facingX >= 0 ? 1 : -1;

  ctx.save();
  ctx.translate(pose.x, pose.y);
  ctx.scale(s, s);

  shadow(ctx, 0, 0, 13, 5.2, 0.26);

  const hipY = -BODY_HEIGHT * 0.42 * squash;
  const shoulderY = -BODY_HEIGHT * 0.82 - bob;

  // --- kaki
  const stepA = easeSwing(pose.phase) * 5.2 * walk;
  const stepB = -stepA;
  drawLeg(ctx, palette, -5, hipY, stepA, side);
  drawLeg(ctx, palette, 5, hipY, stepB, side);

  // --- badan
  const bodyBottom = hipY + 2;
  const bodyTop = shoulderY;
  const torsoWidth = 19;
  if (palette.skirt) {
    poly(
      ctx,
      [
        [-torsoWidth * 0.62, bodyBottom + 3],
        [torsoWidth * 0.62, bodyBottom + 3],
        [torsoWidth * 0.42, bodyTop + 6],
        [-torsoWidth * 0.42, bodyTop + 6],
      ],
      palette.lower,
    );
  } else {
    box(ctx, -torsoWidth * 0.44, bodyTop + 6, torsoWidth * 0.88, bodyBottom - bodyTop - 2, palette.lower, 3);
  }

  box(ctx, -torsoWidth * 0.5, bodyTop, torsoWidth, bodyBottom - bodyTop + 1, back ? palette.shirtDark : palette.shirt, 5);
  // kerah / selendang
  if (palette.scarf) {
    box(ctx, -torsoWidth * 0.5, bodyTop, torsoWidth, 5, palette.accent, 2);
  }
  if (!back) {
    line(ctx, -2.5, bodyTop + 8, -2.5, bodyBottom - 4, alpha(palette.shirtDark, 0.85), 1.4);
  }

  // --- lengan
  const armSwing = easeSwing(pose.phase + 1.6) * 4.4 * walk;
  if (side) {
    const frontX = dir * 7.5;
    line(ctx, frontX, bodyTop + 6, frontX + dir * 1.5, bodyTop + 17 + armSwing, palette.shirt, 5);
    line(ctx, frontX + dir * 1.5, bodyTop + 17 + armSwing, frontX + dir * 1.5, bodyTop + 21 + armSwing, palette.skin, 4.4);
  } else {
    line(ctx, -torsoWidth * 0.58, bodyTop + 7, -torsoWidth * 0.66, bodyTop + 18 - armSwing, palette.shirt, 5);
    line(ctx, torsoWidth * 0.58, bodyTop + 7, torsoWidth * 0.66, bodyTop + 18 + armSwing, palette.shirt, 5);
    line(ctx, -torsoWidth * 0.66, bodyTop + 18 - armSwing, -torsoWidth * 0.66, bodyTop + 22 - armSwing, palette.skin, 4.2);
    line(ctx, torsoWidth * 0.66, bodyTop + 18 + armSwing, torsoWidth * 0.66, bodyTop + 22 + armSwing, palette.skin, 4.2);
  }

  // --- kepala
  const headY = bodyTop - 9.5;
  const headR = 9.4;
  ellipse(ctx, 0, headY, headR, headR * 1.02, palette.skin);
  // telinga
  ellipse(ctx, -headR * 0.96, headY + 1.4, 2.1, 2.8, palette.skin);
  ellipse(ctx, headR * 0.96, headY + 1.4, 2.1, 2.8, palette.skin);

  // rambut
  if (back) {
    ellipse(ctx, 0, headY - 1.4, headR + 0.8, headR * 0.98, palette.hair);
    ellipse(ctx, 0, headY + 3.4, headR - 1.2, headR * 0.6, palette.hair);
  } else {
    ellipse(ctx, 0, headY - 3.2, headR + 0.6, headR * 0.72, palette.hair);
    if (palette.style === 'woman' || palette.style === 'elder') {
      ellipse(ctx, -headR * 0.92, headY + 3.6, 3.2, 5.2, palette.hair);
      ellipse(ctx, headR * 0.92, headY + 3.6, 3.2, 5.2, palette.hair);
    }
  }
  if (palette.bun) {
    ellipse(ctx, 0, headY - headR * 1.06, 4.4, 4, palette.hair);
  }
  if (palette.hat === 'straw') {
    ellipse(ctx, 0, headY - headR * 0.62, headR * 1.85, 4.6, alpha('#c9a35a', 0.98));
    ellipse(ctx, 0, headY - headR * 0.78, headR * 1.05, 5.6, '#d9b46a');
  } else if (palette.hat === 'cap') {
    ellipse(ctx, 0, headY - headR * 0.72, headR * 1.05, headR * 0.62, palette.accent);
    box(ctx, dir > 0 ? 2 : -12, headY - headR * 0.86, 11, 3, palette.accent, 2);
  }

  // --- wajah
  if (!back) {
    const eyeY = headY + 1.4;
    const eyeOffset = side ? 3.4 : 3.6;
    ellipse(ctx, -eyeOffset + (side ? dir * 1.6 : 0), eyeY, 1.25, 1.5, C.hairDark);
    ellipse(ctx, eyeOffset + (side ? dir * 1.6 : 0), eyeY, 1.25, 1.5, C.hairDark);
    if (palette.style === 'elder') {
      line(ctx, -headR * 0.5, headY - 1.6, -headR * 0.16, headY - 2.0, alpha('#4c4034', 0.7), 1);
      line(ctx, headR * 0.16, headY - 2.0, headR * 0.5, headY - 1.6, alpha('#4c4034', 0.7), 1);
    }
    if (palette.style === 'child' || palette.style === 'youth') {
      ellipse(ctx, -eyeOffset, eyeY + 3.6, 1.7, 1.1, alpha('#b7615a', 0.5));
      ellipse(ctx, eyeOffset, eyeY + 3.6, 1.7, 1.1, alpha('#b7615a', 0.5));
    }
  }

  ctx.restore();
}

function drawLeg(ctx: Ctx, palette: CharacterPalette, offsetX: number, hipY: number, swing: number, side: boolean): void {
  const length = side ? 10 + Math.abs(swing) * 0.3 : 10;
  const kneeX = offsetX + (side ? swing * 0.5 : 0);
  line(ctx, offsetX, hipY, kneeX + swing * 0.5, hipY + length, palette.lower, 5.6);
  ellipse(ctx, kneeX + swing * 0.5 + (side ? swing * 0.3 : 0), hipY + length + 0.6, 3.4, 2.2, palette.shoes);
}

/** Potret bulat untuk kotak dialog (padanan TextureFactory.portrait). */
export function drawPortrait(ctx: Ctx, paletteId: string, size: number): void {
  const palette = character(paletteId);
  const s = size / 128;
  ctx.save();
  ctx.clearRect(0, 0, size, size);
  const gradient = ctx.createLinearGradient(0, 0, 0, size);
  gradient.addColorStop(0, '#41413a');
  gradient.addColorStop(1, C.ink);
  ctx.fillStyle = gradient;
  ctx.fillRect(0, 0, size, size);

  ctx.translate(size / 2, size * 0.98);
  ctx.scale(s, s);
  // dada
  box(ctx, -46, -34, 92, 44, palette.shirt, 12);
  box(ctx, -46, -34, 92, 8, palette.shirtDark, 4);
  // leher
  box(ctx, -11, -46, 22, 14, palette.skin, 4);
  // kepala
  ellipse(ctx, 0, -66, 32, 34, palette.skin);
  ellipse(ctx, -32, -62, 7, 10, palette.skin);
  ellipse(ctx, 32, -62, 7, 10, palette.skin);
  // rambut
  ellipse(ctx, 0, -78, 33, 24, palette.hair);
  ellipse(ctx, -31, -58, 9, 18, palette.hair);
  ellipse(ctx, 31, -58, 9, 18, palette.hair);
  if (palette.bun) ellipse(ctx, 0, -102, 15, 13, palette.hair);
  if (palette.hat === 'straw') {
    ellipse(ctx, 0, -86, 60, 15, '#c9a35a');
    ellipse(ctx, 0, -92, 34, 17, '#d9b46a');
  } else if (palette.hat === 'cap') {
    ellipse(ctx, 0, -88, 34, 20, palette.accent);
    box(ctx, 6, -90, 40, 10, palette.accent, 5);
  }
  // wajah
  ellipse(ctx, -12, -66, 3.6, 4.4, C.hairDark);
  ellipse(ctx, 12, -66, 3.6, 4.4, C.hairDark);
  line(ctx, -12, -62, -6, -63, alpha(C.hairDark, 0.5), 1.6);
  line(ctx, 12, -62, 6, -63, alpha(C.hairDark, 0.5), 1.6);
  if (palette.style === 'elder') {
    line(ctx, -18, -74, -6, -75, alpha('#4c4034', 0.7), 2);
    line(ctx, 6, -75, 18, -74, alpha('#4c4034', 0.7), 2);
    line(ctx, -10, -52, 10, -52, alpha('#4c4034', 0.5), 2);
  } else {
    line(ctx, -9, -55, 9, -55, alpha('#8c5a48', 0.75), 2.2);
  }
  if (palette.scarf) box(ctx, -46, -36, 92, 12, palette.accent, 6);
  ctx.restore();

  // bingkai bulat
  ctx.save();
  ring(ctx, size / 2, size / 2, size / 2 - 1.5, size / 2 - 1.5, alpha(C.gold, 0.55), 3, 40);
  ctx.restore();
}
