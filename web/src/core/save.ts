/**
 * SaveManager versi web.
 *
 * Bentuk datanya dibuat sama dengan user://savegame.json versi Godot (screen,
 * flags, items, notes, quests, player, play_time) — hanya tempatnya berbeda:
 * localStorage. Pengaturan suara disimpan terpisah.
 */

import { questOrder, quests } from './data';
import { ensureQuestState, notify, showToast, state } from './store';
import type { QuestState, Vec } from './types';
import { QuestStatus } from './types';

const SAVE_KEY = 'tapak-nusa-save';
const SETTINGS_KEY = 'tapak-nusa-settings';
const SAVE_VERSION = 1;

export interface SaveData {
  version: number;
  saved_at: string;
  screen: string;
  flags: Record<string, boolean | number | string>;
  items: Record<string, number>;
  notes: string[];
  quests: Record<string, { status: number; progress: number[] }>;
  player: Vec | null;
  play_time: number;
  game_finished: boolean;
  game_started: boolean;
}

export interface GameSettings {
  music: number;
  sfx: number;
  ambient: number;
  /** Pengali kecerahan gambar (1 = apa adanya). Berguna di layar yang gelap. */
  brightness: number;
}

export const DEFAULT_SETTINGS: GameSettings = { music: 0.7, sfx: 0.85, ambient: 0.5, brightness: 1.15 };

/** Posisi pemain yang diminta saat memuat; dibaca mesin dunia sekali saja. */
export let pendingPlayerPosition: Vec | null = null;

/** Posisi dari save terakhir; dibaca mesin dunia. Tidak dihapus supaya aman
 *  bila React memuat komponen dua kali saat pengembangan (StrictMode). */
export function getPendingPosition(): Vec | null {
  return pendingPlayerPosition;
}

export function readSave(): SaveData | null {
  try {
    const raw = window.localStorage.getItem(SAVE_KEY);
    if (!raw) return null;
    const parsed = JSON.parse(raw) as SaveData;
    if (!parsed || typeof parsed !== 'object' || !parsed.quests) return null;
    return parsed;
  } catch (error) {
    console.warn('Save tidak bisa dibaca:', error);
    return null;
  }
}

export function hasSave(): boolean {
  return readSave() !== null;
}

export interface SaveSummary {
  savedAt: string;
  playTime: number;
  quest: string;
  finished: boolean;
  notes: number;
}

export function saveSummary(): SaveSummary | null {
  const data = readSave();
  if (!data) return null;
  let questTitle = '';
  for (const questId of questOrder) {
    const entry = data.quests[questId];
    if (entry && entry.status === QuestStatus.Active && !questTitle) {
      questTitle = quests[questId]?.title ?? questId;
    }
  }
  return {
    savedAt: data.saved_at ?? '',
    playTime: data.play_time ?? 0,
    quest: questTitle,
    finished: Boolean(data.game_finished),
    notes: (data.notes ?? []).length,
  };
}

export function serialize(playerPosition: Vec | null = null): SaveData {
  const questData: SaveData['quests'] = {};
  for (const questId of questOrder) {
    const quest: QuestState | undefined = state.quests[questId];
    if (!quest) continue;
    questData[questId] = {
      status: quest.status,
      progress: quest.objectives.map((objective) => objective.progress),
    };
  }
  return {
    version: SAVE_VERSION,
    saved_at: new Date().toISOString(),
    screen: state.screen,
    flags: { ...state.flags },
    items: { ...state.items },
    notes: [...state.notes],
    quests: questData,
    player: playerPosition,
    play_time: state.playTime,
    game_finished: state.gameFinished,
    game_started: state.gameStarted,
  };
}

export function saveGame(playerPosition: Vec | null = null, silent = true): boolean {
  if (!state.gameStarted) return false;
  try {
    window.localStorage.setItem(SAVE_KEY, JSON.stringify(serialize(playerPosition)));
    if (!silent) showToast('Permainan tersimpan', '#8fd5a6');
    return true;
  } catch (error) {
    console.warn('Tidak bisa menyimpan permainan:', error);
    return false;
  }
}

export function loadGame(): boolean {
  const data = readSave();
  if (!data) return false;
  state.flags = { ...(data.flags ?? {}) };
  state.items = { ...(data.items ?? {}) };
  state.notes = [...(data.notes ?? [])];
  state.quests = {};
  for (const [questId, entry] of Object.entries(data.quests ?? {})) {
    const definition = quests[questId];
    if (!definition) continue;
    const quest = ensureQuestState(questId, definition.objectives.length);
    quest.status = entry.status as QuestStatus;
    entry.progress.forEach((progress, index) => {
      if (quest.objectives[index]) quest.objectives[index].progress = progress;
    });
  }
  // Progres puzzle disimpulkan dari quest yang sudah selesai (sama seperti
  // versi Godot: puzzle selesai selalu menyelesaikan questnya).
  state.puzzleDone = {
    pattern: state.quests.q_belajar?.status === QuestStatus.Completed,
    prep: state.quests.q_guyub?.status === QuestStatus.Completed,
  };
  state.playTime = data.play_time ?? 0;
  state.gameStarted = true;
  state.gameFinished = Boolean(data.game_finished);
  state.screen = 'village';
  pendingPlayerPosition = data.player ?? null;
  notify();
  return true;
}

export function deleteSave(): void {
  try {
    window.localStorage.removeItem(SAVE_KEY);
  } catch (error) {
    console.warn('Tidak bisa menghapus simpanan:', error);
  }
  notify();
}

// --- Pengaturan ------------------------------------------------------------

export function loadSettings(): GameSettings {
  try {
    const raw = window.localStorage.getItem(SETTINGS_KEY);
    if (!raw) return { ...DEFAULT_SETTINGS };
    const parsed = JSON.parse(raw) as Partial<GameSettings>;
    return { ...DEFAULT_SETTINGS, ...parsed };
  } catch {
    return { ...DEFAULT_SETTINGS };
  }
}

export function saveSettings(settings: GameSettings): void {
  try {
    window.localStorage.setItem(SETTINGS_KEY, JSON.stringify(settings));
  } catch {
    /* pengaturan tidak wajib tersimpan */
  }
}

/** Menuliskan pengali kecerahan ke variabel CSS yang dipakai lapisan kanvas. */
export function applyBrightness(value: number): void {
  const safe = Number.isFinite(value) ? Math.min(1.8, Math.max(0.6, value)) : 1;
  document.documentElement.style.setProperty('--tapak-brightness', String(safe));
}

export function formatPlayTime(seconds: number): string {
  const total = Math.max(0, Math.floor(seconds));
  const minutes = Math.floor(total / 60);
  const rest = total % 60;
  return `${String(minutes).padStart(2, '0')}:${String(rest).padStart(2, '0')}`;
}
