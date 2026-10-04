/** Bentuk data peta yang dihasilkan tools/gen_village.py (data/world/village.json). */

import type { Rect, Vec } from './types';

export interface PropData {
  id: string;
  kind: string;
  x: number;
  y: number;
  size: Vec | null;
  /** Ukuran gambar (piksel dunia); dihitung tools/gen_village.py dari Prop.gd. */
  w: number;
  h: number;
  /** Kotak tabrakan dengan origin di kiri-atas, atau null bila bisa dilewati. */
  collision: Rect | null;
  variant: number;
  sway: boolean;
  solid: boolean;
  glow: number;
}

export interface NpcData {
  id: string;
  kind: 'npc' | 'villager';
  x: number;
  y: number;
  npc_id: string;
  display_name: string;
  dialogue_id: string;
  palette_id: string;
  start_facing: Vec;
  gather_position: Vec | null;
  alt_quest: string;
  alt_position: Vec | null;
  wander_points: Vec[];
  wander_pause: number;
}

export interface ZoneData {
  id: string;
  rect: Rect;
  title: string;
  subtitle: string;
  flag: string;
}

export interface BoardData {
  id: string;
  x: number;
  y: number;
  dialogue_id: string;
  note_id: string;
  prompt: string;
}

export interface PickupData {
  id: string;
  x: number;
  y: number;
  item_id: string;
  quest_id: string;
  objective_id: string;
  flag_id: string;
}

export interface StationData {
  id: string;
  x: number;
  y: number;
  puzzle_id: string;
  prompt: string;
}

export interface BlockerView {
  id: string;
  x: number;
  y: number;
  w: number;
  h: number;
}

export interface VillageData {
  map: Rect;
  spawn: Vec;
  paths: Rect[];
  plazas: Rect[];
  paddies: Rect[];
  ponds: Rect[];
  gardens: Rect[];
  open_soil: Rect[];
  flowers: Rect[];
  props: PropData[];
  npcs: NpcData[];
  zones: ZoneData[];
  boards: BoardData[];
  pickups: PickupData[];
  stations: StationData[];
  blockers: BlockerView[];
}
