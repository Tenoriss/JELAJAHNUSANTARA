/**
 * Actions — penerjemah "effects" dari data menjadi aksi nyata, plus alur layar.
 *
 * Ini pengganti bagian GameManager versi Godot: pindah layar, mulai/selesai
 * puzzle, efek cerita, dan alur mulai/akhir permainan.
 */

import * as audio from './audio';
import { setEffectHandler } from './bus';
import { itemName, noteTitle } from './data';
import * as dialogue from './dialogue';
import * as quests from './quests';
import { loadGame, saveGame } from './save';
import {
  addItem,
  clearFlag,
  findNote,
  getFlag,
  hasFlag,
  missingItems,
  notify,
  removeItem,
  resetState,
  setFlag,
  showBanner,
  showToast,
  state,
} from './store';
import type { Effects, PuzzleId, ScreenId } from './types';

/** Dialog yang dijalankan setelah masing-masing puzzle selesai (lihat data). */
const PUZZLE_SUCCESS_DIALOGUES: Record<PuzzleId, string> = {
  pattern: 'pak_jaya_sukses',
  prep: 'guyub_siap',
};

const DRAW_SHORT = 900; // ms jeda sebelum dialog lanjutan setelah puzzle

// --- Alur permainan --------------------------------------------------------

export function newGame(): void {
  resetState();
  state.gameStarted = true;
  state.screen = 'opening';
  audio.playMusic('menu');
  notify();
}

export function continueGame(): boolean {
  if (!loadGame()) return false;
  state.gameStarted = true;
  state.screen = 'village';
  notify();
  return true;
}

/** Permintaan pindah layar yang datang saat fade berjalan tidak dibuang,
 *  melainkan dijalankan setelah fadenya selesai. */
let pendingScreen: ScreenId | null = null;

export function goto(screen: ScreenId): void {
  if (state.transitioning) {
    pendingScreen = screen;
    return;
  }
  state.screen = screen;
  state.transitioning = true;
  state.menuPanel = null;
  notify();
  window.setTimeout(() => {
    state.transitioning = false;
    const next = pendingScreen;
    pendingScreen = null;
    if (next !== null && next !== state.screen) {
      goto(next);
      return;
    }
    notify();
  }, 420);
  if (screen === 'village') audio.playMusic('village');
  else if (screen === 'ending') audio.playMusic('ending');
  else if (screen === 'main_menu' || screen === 'credits' || screen === 'opening') {
    audio.playMusic('menu');
  }
  if (screen === 'village') audio.playAmbient('day');
  else audio.stopAmbient();
}

export function returnToMainMenu(): void {
  dialogue.abort();
  setPaused(false);
  state.gameStarted = false;
  audio.stopAmbient();
  state.screen = 'main_menu';
  notify();
  audio.playMusic('menu');
}

export function finishGame(): void {
  state.gameFinished = true;
  setFlag('game_finished', true);
  saveGame();
  goto('ending');
}

export function setPaused(value: boolean): void {
  if (state.paused === value) return;
  state.paused = value;
  if (!value) state.menuPanel = null;
  notify();
}

export function canPlayerAct(): boolean {
  if (!state.gameStarted || state.transitioning || state.paused) return false;
  if (state.puzzle !== null) return false;
  if (dialogue.isActive()) return false;
  return true;
}

// --- Puzzle ----------------------------------------------------------------

export function startPuzzle(puzzleId: PuzzleId): void {
  if (state.puzzle !== null) return;
  state.puzzle = puzzleId;
  dialogue.abort();
  setPaused(true);
  notify();
}

export function finishPuzzle(puzzleId: PuzzleId, success: boolean): void {
  state.puzzle = null;
  setPaused(false);
  if (!success) {
    notify();
    return;
  }
  state.puzzleDone[puzzleId] = true;
  setFlag(`puzzle_${puzzleId}_done`, true);
  audio.playSfx('success');
  showToast('Puzzle selesai!', '#8fd5a6');
  notify();
  const followUp = PUZZLE_SUCCESS_DIALOGUES[puzzleId];
  if (followUp) {
    window.setTimeout(() => dialogue.start(followUp), DRAW_SHORT);
  }
}

// --- Efek dari data --------------------------------------------------------

export function applyEffects(effects: Effects): void {
  if (!effects) return;
  if (effects.sfx) audio.playSfx(effects.sfx);
  if (effects.message) showToast(effects.message, '#f2b134');
  if (effects.banner) showBanner(effects.banner, effects.banner_subtitle ?? '');
  if (effects.set_flags) {
    for (const [key, value] of Object.entries(effects.set_flags)) setFlag(key, value);
  }
  if (effects.clear_flags) effects.clear_flags.forEach((flag) => clearFlag(flag));
  if (effects.give_items) effects.give_items.forEach((itemId) => addItem(itemId));
  if (effects.remove_items) effects.remove_items.forEach((itemId) => removeItem(itemId));
  if (effects.note) {
    findNote(effects.note);
    audio.playSfx('note');
    showToast(`Catatan Budaya: ${noteTitle(effects.note)}`, '#f7d68a');
  }
  if (effects.start_quest) quests.startQuest(effects.start_quest);
  if (effects.start_quests) effects.start_quests.forEach((questId) => quests.startQuest(questId));
  if (effects.advance_objectives) {
    effects.advance_objectives.forEach((entry) => {
      quests.advanceObjective(entry.quest, entry.objective, entry.amount ?? 1);
    });
  }
  if (effects.complete_objectives) {
    effects.complete_objectives.forEach((entry) => {
      quests.completeObjective(entry.quest, entry.objective);
    });
  }
  if (effects.complete_quest) quests.completeQuest(effects.complete_quest);
  if (effects.complete_quests) effects.complete_quests.forEach((questId) => quests.completeQuest(questId));

  // Aksi yang mengubah layar dijalankan paling akhir dan ditunda satu putaran,
  // supaya dialog/puzzle yang memanggilnya sempat ditutup dengan rapi.
  if (effects.start_puzzle) {
    const puzzleId = effects.start_puzzle;
    window.setTimeout(() => startPuzzle(puzzleId), 60);
  }
  if (effects.start_dialogue) {
    const dialogueId = effects.start_dialogue;
    window.setTimeout(() => dialogue.start(dialogueId), 120);
  }
  if (effects.goto_screen) {
    const screen = effects.goto_screen;
    window.setTimeout(() => goto(screen), 200);
  }
  if (effects.finish_game) {
    window.setTimeout(() => finishGame(), 260);
  }
}

setEffectHandler((effects) => {
  try {
    applyEffects(effects);
  } catch (error) {
    console.error('Gagal menjalankan efek:', error);
  }
});

// --- Interaksi dunia -------------------------------------------------------

/** Ambil barang dari dunia (ItemPickup). */
export function collectItem(pickup: {
  item_id: string;
  quest_id: string;
  objective_id: string;
  flag_id: string;
}): void {
  const flag = pickup.flag_id || `took_${pickup.item_id}`;
  addItem(pickup.item_id, 1);
  if (pickup.quest_id && pickup.objective_id) {
    quests.advanceObjective(pickup.quest_id, pickup.objective_id, 1);
  }
  setFlag(flag, true);
  audio.playSfx('pickup');
  showToast(`Mendapat ${itemName(pickup.item_id)}`, '#f2b134');
}

/** Baca papan / periksa objek informasi. */
export function readBoard(board: { dialogue_id: string; note_id: string }): void {
  if (board.note_id) {
    findNote(board.note_id);
    audio.playSfx('note');
    showToast(`Catatan Budaya: ${noteTitle(board.note_id)}`, '#f7d68a');
  }
  if (board.dialogue_id) dialogue.start(board.dialogue_id);
}

/** Stasiun persiapan Lapangan Guyub. */
export function useStation(
  required: readonly string[],
  puzzleId: PuzzleId,
  readyDialogue: string,
  missingDialogue: string,
): void {
  if (hasFlag(`puzzle_${puzzleId}_done`)) {
    dialogue.start(readyDialogue);
    return;
  }
  const missing = missingItems(required);
  if (missing.length === 0) {
    startPuzzle(puzzleId);
    return;
  }
  const names = missing.map((itemId) => itemName(itemId)).join(', ');
  showToast(`Masih kurang: ${names}`, '#f7d68a');
  dialogue.start(missingDialogue);
}

/** Bicara dengan NPC. */
export function talkTo(npc: { npc_id: string; dialogue_id: string }): void {
  setFlag(`met_${npc.npc_id}`, true);
  if (npc.dialogue_id) dialogue.start(npc.dialogue_id);
}

export function flag(name: string): boolean {
  return getFlag(name) === true;
}
