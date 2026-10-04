/**
 * Pemuatan data cerita.
 *
 * Semua berkas di data/ dipakai bersama dengan versi Godot — tidak ada salinan
 * kedua di dalam web/. Bila naskah dialog diubah, kedua versi ikut berubah.
 */

import type { DialogueFile, DialogueNode, ItemDef, NoteDef, QuestDefs } from './types';
import type { VillageData } from './villageTypes';
import villageJson from '@data/world/village.json';
import questsJson from '@data/quests/quests.json';
import itemsJson from '@data/items/items.json';
import notesJson from '@data/notes/cultural_notes.json';

// Diimpor satu per satu (bukan glob) supaya berkas yang sama bisa dibaca juga
// oleh uji Node tanpa Vite. Menambah naskah baru = tambah satu baris di sini.
import buRiniDialogue from '@data/dialogue/bu_rini.json';
import dimasDialogue from '@data/dialogue/dimas.json';
import eventDialogue from '@data/dialogue/event.json';
import mbahSenoDialogue from '@data/dialogue/mbah_seno.json';
import openingDialogue from '@data/dialogue/opening.json';
import pakJayaDialogue from '@data/dialogue/pak_jaya.json';
import sariDialogue from '@data/dialogue/sari.json';
import villagersDialogue from '@data/dialogue/villagers.json';
import worldObjectsDialogue from '@data/dialogue/world_objects.json';

/** Seluruh berkas dialog, digabung: id dialog -> node-node. */
export const dialogue: DialogueFile = Object.assign(
  {},
  buRiniDialogue,
  dimasDialogue,
  eventDialogue,
  mbahSenoDialogue,
  openingDialogue,
  pakJayaDialogue,
  sariDialogue,
  villagersDialogue,
  worldObjectsDialogue,
) as DialogueFile;

export const quests = questsJson as QuestDefs;
export const items = itemsJson as Record<string, ItemDef>;
export const notes = notesJson as Record<string, NoteDef>;
export const village = villageJson as VillageData;

/** Urutan quest menurut data (untuk penunjuk tujuan utama di HUD). */
export const questOrder: string[] = Object.keys(quests).sort(
  (a, b) => quests[a].order - quests[b].order,
);

export function dialogueNodes(dialogueId: string): DialogueNode[] {
  return dialogue[dialogueId]?.nodes ?? [];
}

export function itemName(itemId: string): string {
  return items[itemId]?.name ?? itemId;
}

export function itemIcon(itemId: string): string {
  return items[itemId]?.icon ?? 'bambu';
}

export function itemColor(itemId: string): string {
  return items[itemId]?.color ?? '#f2b134';
}

export function noteTitle(noteId: string): string {
  return notes[noteId]?.title ?? noteId;
}

export function noteText(noteId: string): string {
  return notes[noteId]?.text ?? '';
}

export function totalNotes(): number {
  return Object.keys(notes).length;
}
