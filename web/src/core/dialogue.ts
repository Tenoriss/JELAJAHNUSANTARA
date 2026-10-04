/**
 * DialogueManager — memilih cabang dialog sesuai keadaan cerita, menampilkan
 * satu baris demi satu baris, lalu menjalankan efek node saat dialog selesai.
 *
 * Bentuk data sama seperti versi Godot: setiap dialog punya beberapa "node"
 * dengan conditions + priority; yang menang adalah prioritas tertinggi yang
 * kondisinya terpenuhi.
 */

import { applyEffects } from './bus';
import { dialogueNodes } from './data';
import { conditionsMet } from './quests';
import { notify, state } from './store';
import type { Effects, Line } from './types';

let currentId = '';
let currentLines: Line[] = [];
let currentIndex = 0;
let currentEffects: Record<string, unknown> | null = null;
let queue: { id?: string; lines?: Line[] }[] = [];

export function isActive(): boolean {
  return state.dialogue !== null;
}

/** Nama dialog yang sedang berjalan (kosong bila tidak ada). */
export function activeId(): string {
  return state.dialogue?.dialogueId ?? '';
}

function resolveNode(dialogueId: string, lines?: Line[]): { lines: Line[]; effects: Record<string, unknown> | null } | null {
  if (lines) return { lines, effects: null };
  const nodes = dialogueNodes(dialogueId);
  if (nodes.length === 0) return null;
  let best = null as (typeof nodes)[number] | null;
  let bestPriority = -9999;
  for (const node of nodes) {
    if (!conditionsMet(node.conditions as Record<string, unknown> | undefined)) continue;
    const priority = node.priority ?? 0;
    if (priority > bestPriority) {
      bestPriority = priority;
      best = node;
    }
  }
  if (!best) return null;
  return { lines: best.lines, effects: (best.effects as Record<string, unknown>) ?? null };
}

export function start(dialogueId: string): boolean {
  const resolved = resolveNode(dialogueId);
  if (!resolved) {
    console.warn(`Dialog '${dialogueId}' tidak punya node yang cocok.`);
    return false;
  }
  if (isActive()) {
    queue.push({ id: dialogueId });
    return true;
  }
  currentId = dialogueId;
  currentLines = resolved.lines;
  currentIndex = 0;
  currentEffects = resolved.effects;
  showCurrent();
  return true;
}

export function startLines(lines: Line[], id = 'dynamic'): boolean {
  if (lines.length === 0) return false;
  if (isActive()) {
    queue.push({ lines });
    return true;
  }
  currentId = id;
  currentLines = lines;
  currentIndex = 0;
  currentEffects = null;
  showCurrent();
  return true;
}

export function advance(): void {
  if (!isActive()) return;
  currentIndex += 1;
  if (currentIndex >= currentLines.length) finish();
  else showCurrent();
}

/** Menutup dialog tanpa menjalankan efeknya (pindah layar / mulai ulang). */
export function abort(): void {
  if (!isActive()) return;
  currentLines = [];
  currentIndex = 0;
  currentEffects = null;
  currentId = '';
  queue = [];
  state.dialogue = null;
  notify();
}

function showCurrent(): void {
  const line = currentLines[currentIndex];
  if (!line) {
    finish();
    return;
  }
  const speaker = line.speaker ?? '';
  const narration = Boolean(line.narration) || speaker.length === 0;
  state.dialogue = {
    dialogueId: currentId,
    index: currentIndex,
    total: currentLines.length,
    speaker,
    text: line.text,
    portrait: line.portrait ?? '',
    color: line.color ?? '#f2b134',
    narration,
    hasMore: currentIndex < currentLines.length - 1,
    pause: line.pause ?? -1,
  };
  notify();
}

function finish(): void {
  const effects = currentEffects;
  const finishedId = currentId;
  currentLines = [];
  currentIndex = 0;
  currentEffects = null;
  currentId = '';
  state.dialogue = null;
  notify();
  dialogueFinished(finishedId);
  if (effects) applyEffects(effects as Effects);
  const next = queue.shift();
  if (next) {
    if (next.lines) startLines(next.lines);
    else if (next.id) start(next.id);
  }
}

/** Daftar pendengar "dialog selesai" (dipakai layar pembuka & penutup). */
const finishedListeners = new Set<(dialogueId: string) => void>();

export function onFinished(listener: (dialogueId: string) => void): () => void {
  finishedListeners.add(listener);
  return () => finishedListeners.delete(listener);
}

function dialogueFinished(dialogueId: string): void {
  finishedListeners.forEach((listener) => listener(dialogueId));
}
