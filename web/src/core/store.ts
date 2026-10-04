/**
 * Store permainan (pengganti autoload GameManager versi Godot).
 *
 * Sederhana dan tanpa dependensi: satu objek keadaan + daftar pelanggan.
 * Komponen React membaca lewat hook useGame().
 */

import { useSyncExternalStore } from 'react';
import type { DialogueView, PuzzleId, QuestState, ScreenId } from './types';
import { QuestStatus } from './types';

export interface Toast {
  id: number;
  text: string;
  color: string;
}

export interface Banner {
  id: number;
  title: string;
  subtitle: string;
}

export interface AreaLabel {
  id: number;
  title: string;
  subtitle: string;
}

export interface GameState {
  /** Naik setiap ada perubahan; dipakai React untuk menggambar ulang. */
  version: number;
  screen: ScreenId;
  gameStarted: boolean;
  gameFinished: boolean;
  transitioning: boolean;
  paused: boolean;
  puzzle: PuzzleId | null;
  puzzleDone: Record<string, boolean>;
  flags: Record<string, boolean | number | string>;
  items: Record<string, number>;
  notes: string[];
  quests: Record<string, QuestState>;
  playTime: number;
  dialogue: DialogueView | null;
  toasts: Toast[];
  banner: Banner | null;
  area: AreaLabel | null;
  /** Teks balon interaksi yang sedang aktif (null bila tidak ada). */
  prompt: string | null;
  /** Panel mana yang terbuka di menu jeda: 'pause' | 'quests' | ... | null. */
  menuPanel: 'pause' | 'quests' | 'inventory' | 'notes' | 'settings' | null;
  /** Panel catatan budaya yang sedang dibaca (id catatan). */
  noteReader: string | null;
}

const listeners = new Set<() => void>();
let nextId = 1;

export const state: GameState = {
  version: 0,
  screen: 'main_menu',
  gameStarted: false,
  gameFinished: false,
  transitioning: false,
  paused: false,
  puzzle: null,
  puzzleDone: {},
  flags: {},
  items: {},
  notes: [],
  quests: {},
  playTime: 0,
  dialogue: null,
  toasts: [],
  banner: null,
  area: null,
  prompt: null,
  menuPanel: null,
  noteReader: null,
};

export function subscribe(listener: () => void): () => void {
  listeners.add(listener);
  return () => listeners.delete(listener);
}

export function notify(): void {
  state.version += 1;
  listeners.forEach((listener) => listener());
}

/** Hook React: komponen digambar ulang setiap keadaan berubah. */
export function useGame(): GameState {
  useSyncExternalStore(subscribe, () => state.version, () => state.version);
  return state;
}

// --- Flag cerita -----------------------------------------------------------

export function setFlag(name: string, value: boolean | number | string = true): void {
  state.flags[name] = value;
  notify();
}

export function getFlag(name: string, fallback: boolean | number | string = false): boolean | number | string {
  return name in state.flags ? state.flags[name] : fallback;
}

export function hasFlag(name: string): boolean {
  const value = state.flags[name];
  if (value === undefined) return false;
  if (typeof value === 'boolean') return value;
  if (typeof value === 'number') return value !== 0;
  return String(value).length > 0;
}

export function clearFlag(name: string): void {
  delete state.flags[name];
  notify();
}

// --- Barang ----------------------------------------------------------------

export function addItem(itemId: string, amount = 1): void {
  state.items[itemId] = (state.items[itemId] ?? 0) + amount;
  notify();
}

export function hasItem(itemId: string, amount = 1): boolean {
  return (state.items[itemId] ?? 0) >= amount;
}

export function removeItem(itemId: string, amount = 1): boolean {
  const have = state.items[itemId] ?? 0;
  if (have < amount) return false;
  if (have === amount) delete state.items[itemId];
  else state.items[itemId] = have - amount;
  notify();
  return true;
}

export function missingItems(required: readonly string[]): string[] {
  return required.filter((itemId) => !hasItem(itemId));
}

// --- Catatan budaya --------------------------------------------------------

export function findNote(noteId: string): void {
  if (!noteId || state.notes.includes(noteId)) return;
  state.notes.push(noteId);
  notify();
}

export function hasNote(noteId: string): boolean {
  return state.notes.includes(noteId);
}

// --- Umpan balik UI --------------------------------------------------------

export function showToast(text: string, color = '#f6ead6'): void {
  const id = nextId++;
  state.toasts = [...state.toasts.slice(-3), { id, text, color }];
  notify();
  window.setTimeout(() => {
    state.toasts = state.toasts.filter((toast) => toast.id !== id);
    notify();
  }, 3200);
}

export function showBanner(title: string, subtitle = ''): void {
  const id = nextId++;
  state.banner = { id, title, subtitle };
  notify();
  window.setTimeout(() => {
    if (state.banner?.id === id) {
      state.banner = null;
      notify();
    }
  }, 3000);
}

export function showArea(title: string, subtitle: string): void {
  const id = nextId++;
  state.area = { id, title, subtitle };
  notify();
  window.setTimeout(() => {
    if (state.area?.id === id) {
      state.area = null;
      notify();
    }
  }, 2600);
}

// --- Quest -----------------------------------------------------------------

export function ensureQuestState(questId: string, objectiveCount: number): QuestState {
  let quest = state.quests[questId];
  if (!quest) {
    quest = {
      status: QuestStatus.Inactive,
      objectives: Array.from({ length: objectiveCount }, () => ({ progress: 0 })),
    };
    state.quests[questId] = quest;
  }
  return quest;
}

// --- Lain-lain -------------------------------------------------------------

export function resetState(): void {
  state.flags = {};
  state.items = {};
  state.notes = [];
  state.quests = {};
  state.puzzleDone = {};
  state.playTime = 0;
  state.gameFinished = false;
  state.gameStarted = false;
  state.puzzle = null;
  state.dialogue = null;
  state.toasts = [];
  state.banner = null;
  state.area = null;
  state.prompt = null;
  state.menuPanel = null;
  state.noteReader = null;
  state.paused = false;
  notify();
}
