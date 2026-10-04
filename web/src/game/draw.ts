/**
 * Alat gambar dasar untuk Canvas 2D (padanan DrawKit.gd versi Godot).
 */

import { alpha, C } from './palette';

export type Ctx = CanvasRenderingContext2D;

export const FONT_STACK = '"Segoe UI", system-ui, -apple-system, "Helvetica Neue", Arial, sans-serif';

export function font(size: number, weight: 'normal' | 'bold' = 'normal'): string {
  return `${weight} ${size}px ${FONT_STACK}`;
}

export function roundRectPath(ctx: Ctx, x: number, y: number, w: number, h: number, r: number): void {
  const radius = Math.max(0, Math.min(r, Math.min(w, h) * 0.5));
  ctx.beginPath();
  ctx.moveTo(x + radius, y);
  ctx.lineTo(x + w - radius, y);
  ctx.quadraticCurveTo(x + w, y, x + w, y + radius);
  ctx.lineTo(x + w, y + h - radius);
  ctx.quadraticCurveTo(x + w, y + h, x + w - radius, y + h);
  ctx.lineTo(x + radius, y + h);
  ctx.quadraticCurveTo(x, y + h, x, y + h - radius);
  ctx.lineTo(x, y + radius);
  ctx.quadraticCurveTo(x, y, x + radius, y);
  ctx.closePath();
}

export function box(ctx: Ctx, x: number, y: number, w: number, h: number, color: string, r = 4): void {
  ctx.fillStyle = color;
  roundRectPath(ctx, x, y, w, h, r);
  ctx.fill();
}

export function boxBorder(
  ctx: Ctx,
  x: number,
  y: number,
  w: number,
  h: number,
  fill: string | null,
  border: string,
  lineWidth = 2,
  r = 6,
): void {
  roundRectPath(ctx, x, y, w, h, r);
  if (fill) {
    ctx.fillStyle = fill;
    ctx.fill();
  }
  ctx.strokeStyle = border;
  ctx.lineWidth = lineWidth;
  ctx.stroke();
}

export function ellipse(ctx: Ctx, cx: number, cy: number, rx: number, ry: number, color: string): void {
  ctx.fillStyle = color;
  ctx.beginPath();
  ctx.ellipse(cx, cy, Math.max(0.1, rx), Math.max(0.1, ry), 0, 0, Math.PI * 2);
  ctx.fill();
}

export function ring(
  ctx: Ctx,
  cx: number,
  cy: number,
  rx: number,
  ry: number,
  color: string,
  lineWidth = 2,
  segments = 24,
): void {
  ctx.strokeStyle = color;
  ctx.lineWidth = lineWidth;
  ctx.beginPath();
  for (let i = 0; i <= segments; i += 1) {
    const angle = (i / segments) * Math.PI * 2;
    const px = cx + Math.cos(angle) * rx;
    const py = cy + Math.sin(angle) * ry;
    if (i === 0) ctx.moveTo(px, py);
    else ctx.lineTo(px, py);
  }
  ctx.stroke();
}

export function poly(ctx: Ctx, points: readonly [number, number][], color: string): void {
  if (points.length === 0) return;
  ctx.fillStyle = color;
  ctx.beginPath();
  ctx.moveTo(points[0][0], points[0][1]);
  for (let i = 1; i < points.length; i += 1) ctx.lineTo(points[i][0], points[i][1]);
  ctx.closePath();
  ctx.fill();
}

export function line(
  ctx: Ctx,
  x1: number,
  y1: number,
  x2: number,
  y2: number,
  color: string,
  width = 2,
): void {
  ctx.strokeStyle = color;
  ctx.lineWidth = width;
  ctx.lineCap = 'round';
  ctx.beginPath();
  ctx.moveTo(x1, y1);
  ctx.lineTo(x2, y2);
  ctx.stroke();
}

/** Bayangan lembut di bawah objek (bd, bukan bayangan jatuh yang rumit). */
export function shadow(ctx: Ctx, cx: number, cy: number, rx: number, ry: number, opacity = 0.22): void {
  ellipse(ctx, cx, cy, rx, ry, alpha('#0d0a08', opacity));
}

export function text(
  ctx: Ctx,
  value: string,
  x: number,
  y: number,
  size: number,
  color: string,
  align: CanvasTextAlign = 'left',
  weight: 'normal' | 'bold' = 'normal',
): void {
  ctx.font = font(size, weight);
  ctx.textAlign = align;
  ctx.textBaseline = 'alphabetic';
  ctx.fillStyle = color;
  ctx.fillText(value, x, y);
}

export function textCentered(
  ctx: Ctx,
  value: string,
  cx: number,
  y: number,
  size: number,
  color: string,
  weight: 'normal' | 'bold' = 'normal',
): void {
  text(ctx, value, cx, y, size, color, 'center', weight);
}

export function wrapText(ctx: Ctx, value: string, maxWidth: number, size: number): string[] {
  ctx.font = font(size);
  const words = value.split(' ');
  const lines: string[] = [];
  let line = '';
  for (const word of words) {
    const next = line ? `${line} ${word}` : word;
    if (ctx.measureText(next).width > maxWidth && line) {
      lines.push(line);
      line = word;
    } else {
      line = next;
    }
  }
  if (line) lines.push(line);
  return lines;
}

/** Balon teks kecil (dipakai untuk prompt interaksi di dunia). */
export function bubble(ctx: Ctx, cx: number, cy: number, label: string, key: string, size = 14): void {
  ctx.font = font(size, 'bold');
  const textWidth = ctx.measureText(label).width;
  const badge = 24;
  const padding = 12;
  const width = textWidth + badge + padding * 2.4;
  const height = 32;
  const x = cx - width / 2;
  const y = cy - height;

  shadow(ctx, cx, cy + 4, width * 0.45, 7, 0.24);
  boxBorder(ctx, x, y, width, height, alpha(C.ink, 0.92), alpha(C.gold, 0.55), 2, 12);
  // ekor balon
  poly(
    ctx,
    [
      [cx - 7, y + height - 1],
      [cx + 7, y + height - 1],
      [cx, y + height + 8],
    ],
    alpha(C.ink, 0.92),
  );
  box(ctx, x + padding * 0.6, y + 5, badge - 6, height - 10, alpha(C.gold, 0.9), 6);
  textCentered(ctx, key, x + padding * 0.6 + (badge - 6) / 2, y + height / 2 + 5, size, C.ink, 'bold');
  text(ctx, label, x + padding * 1.5 + badge - 4, y + height / 2 + 5, size, C.cream, 'left', 'bold');
}
