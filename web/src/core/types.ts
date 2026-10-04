/** Tipe data bersama untuk seluruh permainan. */

export type Vec = { x: number; y: number };
export type Rect = { x: number; y: number; w: number; h: number };

export type ScreenId = 'main_menu' | 'opening' | 'village' | 'ending' | 'credits';
export type PuzzleId = 'pattern' | 'prep';

/** Aksi yang ditulis pada data dialog/quest (lihat data/*.json). */
export interface Effects {
  sfx?: string;
  message?: string;
  banner?: string;
  banner_subtitle?: string;
  set_flags?: Record<string, boolean | number | string>;
  clear_flags?: string[];
  give_items?: string[];
  remove_items?: string[];
  note?: string;
  start_quest?: string;
  start_quests?: string[];
  advance_objectives?: { quest: string; objective: string; amount?: number }[];
  complete_objectives?: { quest: string; objective: string }[];
  complete_quest?: string;
  complete_quests?: string[];
  start_puzzle?: PuzzleId;
  start_dialogue?: string;
  goto_screen?: ScreenId;
  finish_game?: boolean;
}

export interface Line {
  speaker?: string;
  text: string;
  portrait?: string;
  color?: string;
  narration?: boolean;
  /** Jeda otomatis (detik) sebelum baris lanjut sendiri. */
  pause?: number;
}

export interface Conditions {
  quest_active?: string | string[];
  quest_completed?: string | string[];
  quest_not_started?: string | string[];
  quest_not_completed?: string | string[];
  flags?: Record<string, boolean | number | string>;
  not_flags?: Record<string, boolean | number | string>;
  items?: string[];
  missing_items?: string[];
  notes?: string[];
  game_finished?: boolean;
}

export interface DialogueNode {
  id: string;
  priority?: number;
  conditions?: Conditions;
  lines: Line[];
  effects?: Effects;
}

export interface DialogueFile {
  [dialogueId: string]: { nodes: DialogueNode[] };
}

export interface QuestObjectiveDef {
  id: string;
  text: string;
  required: number;
  item?: string;
}

export interface QuestDef {
  title: string;
  description: string;
  order: number;
  objectives: QuestObjectiveDef[];
  on_start?: Effects;
  on_complete?: Effects;
}

export type QuestDefs = Record<string, QuestDef>;

export enum QuestStatus {
  Inactive = 0,
  Active = 1,
  Completed = 2,
}

export interface QuestObjectiveState {
  progress: number;
}

export interface QuestState {
  status: QuestStatus;
  objectives: QuestObjectiveState[];
}

export interface ItemDef {
  name: string;
  description?: string;
  color?: string;
  icon?: string;
}

export interface NoteDef {
  title: string;
  text: string;
}

/** Satu baris yang sedang ditampilkan DialogueBox. */
export interface DialogueView {
  dialogueId: string;
  index: number;
  total: number;
  speaker: string;
  text: string;
  portrait: string;
  color: string;
  narration: boolean;
  hasMore: boolean;
  pause: number;
}
