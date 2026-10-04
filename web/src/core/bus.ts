/**
 * Bus efek: jalan pintas supaya quest dan dialog bisa memicu "effects"
 * (lihat data/*.json) tanpa impor melingkar dengan actions.ts.
 */

import type { Effects } from './types';

type Handler = (effects: Effects) => void;

let handler: Handler | null = null;

export function setEffectHandler(next: Handler): void {
  handler = next;
}

export function applyEffects(effects: Effects): void {
  handler?.(effects);
}
