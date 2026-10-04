/**
 * QuestManager — memuat daftar quest dari data/quests/quests.json, menyimpan
 * progres, dan menjalankan efek yang tertulis di data (on_start / on_complete).
 *
 * Dasar sama dengan versi Godot: quest selesai otomatis begitu semua
 * objective-nya terpenuhi.
 */

import { questOrder, quests } from './data';
import { ensureQuestState, getFlag, hasItem, hasNote, notify, state } from './store';
import type { Effects, QuestDef, QuestState } from './types';
import { applyEffects } from './bus';
import { QuestStatus } from './types';

let applying = false;

function def(questId: string): QuestDef | null {
  return quests[questId] ?? null;
}

function questState(questId: string): QuestState | null {
  const definition = def(questId);
  if (!definition) return null;
  return ensureQuestState(questId, definition.objectives.length);
}

export function isActive(questId: string): boolean {
  return state.quests[questId]?.status === QuestStatus.Active;
}

export function isCompleted(questId: string): boolean {
  return state.quests[questId]?.status === QuestStatus.Completed;
}

export function hasStarted(questId: string): boolean {
  const quest = state.quests[questId];
  return !!quest && quest.status !== QuestStatus.Inactive;
}

export function objectiveProgress(questId: string, index: number): number {
  return state.quests[questId]?.objectives[index]?.progress ?? 0;
}

export function isObjectiveDone(questId: string, index: number): boolean {
  const definition = def(questId);
  if (!definition) return false;
  const required = definition.objectives[index]?.required ?? 1;
  return objectiveProgress(questId, index) >= required;
}

/** Quest aktif pertama menurut urutan data (penunjuk tujuan utama di HUD). */
export function currentQuestId(): string | null {
  for (const questId of questOrder) {
    if (isActive(questId)) return questId;
  }
  return null;
}

export function activeQuests(): string[] {
  return questOrder.filter((questId) => isActive(questId));
}

export function completedQuests(): string[] {
  return questOrder.filter((questId) => isCompleted(questId));
}

export function startQuest(questId: string): boolean {
  const definition = def(questId);
  const quest = questState(questId);
  if (!definition || !quest || quest.status !== QuestStatus.Inactive) return false;
  quest.status = QuestStatus.Active;
  notify();
  applyQuestEffects(definition.on_start);
  checkAutoComplete(questId);
  return true;
}

export function advanceObjective(questId: string, objectiveId: string, amount = 1): void {
  const definition = def(questId);
  const quest = questState(questId);
  if (!definition || !quest || quest.status === QuestStatus.Completed) return;
  const index = definition.objectives.findIndex((objective) => objective.id === objectiveId);
  if (index < 0) return;
  const required = definition.objectives[index].required;
  const objective = quest.objectives[index];
  if (objective.progress >= required) return;
  objective.progress = Math.min(required, objective.progress + amount);
  notify();
  checkAutoComplete(questId);
}

export function completeObjective(questId: string, objectiveId: string): void {
  const definition = def(questId);
  if (!definition) return;
  const index = definition.objectives.findIndex((objective) => objective.id === objectiveId);
  if (index < 0) return;
  advanceObjective(questId, objectiveId, definition.objectives[index].required);
}

export function completeQuest(questId: string): void {
  const definition = def(questId);
  const quest = questState(questId);
  if (!definition || !quest || quest.status === QuestStatus.Completed) return;
  quest.objectives.forEach((objective, index) => {
    objective.progress = definition.objectives[index]?.required ?? 1;
  });
  quest.status = QuestStatus.Completed;
  notify();
  applyQuestEffects(definition.on_complete);
}

function checkAutoComplete(questId: string): void {
  const definition = def(questId);
  const quest = state.quests[questId];
  if (!definition || !quest || quest.status !== QuestStatus.Active) return;
  const done = definition.objectives.every((objective, index) => {
    return (quest.objectives[index]?.progress ?? 0) >= objective.required;
  });
  if (done) completeQuest(questId);
}

function applyQuestEffects(effects: Effects | undefined): void {
  if (!effects || applying) return;
  applying = true;
  applyEffects(effects);
  applying = false;
}

// --- Kondisi untuk dialog --------------------------------------------------

export function conditionsMet(conditions: Record<string, unknown> | undefined): boolean {
  if (!conditions || Object.keys(conditions).length === 0) return true;
  const list = (value: unknown): string[] => (Array.isArray(value) ? value.map(String) : [String(value)]);

  if (conditions.quest_active && !list(conditions.quest_active).some(isActive)) return false;
  if (conditions.quest_completed && !list(conditions.quest_completed).some(isCompleted)) return false;
  if (conditions.quest_not_started && list(conditions.quest_not_started).some(hasStarted)) return false;
  if (conditions.quest_not_completed && list(conditions.quest_not_completed).some(isCompleted)) return false;

  const flags = conditions.flags as Record<string, unknown> | undefined;
  if (flags) {
    for (const [key, value] of Object.entries(flags)) {
      if (getFlag(key) !== value) return false;
    }
  }
  const notFlags = conditions.not_flags as Record<string, unknown> | undefined;
  if (notFlags) {
    for (const [key, value] of Object.entries(notFlags)) {
      if (getFlag(key) === value) return false;
    }
  }
  const itemList = conditions.items as string[] | undefined;
  if (itemList && !itemList.every((itemId) => hasItem(itemId))) return false;
  const missing = conditions.missing_items as string[] | undefined;
  if (missing && !missing.every((itemId) => !hasItem(itemId))) return false;
  const noteList = conditions.notes as string[] | undefined;
  if (noteList && !noteList.every((noteId) => hasNote(noteId))) return false;
  if (conditions.game_finished !== undefined) {
    if (state.gameFinished !== Boolean(conditions.game_finished)) return false;
  }
  return true;
}
