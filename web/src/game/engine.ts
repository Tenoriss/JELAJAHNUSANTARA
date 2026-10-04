/**
 * Mesin dunia Desa Arunika (padanan Village.gd + Player.gd + PlayerInteractor.gd).
 *
 * Mengurus: pergerakan Raka, tabrakan, kamera, urutan gambar atas-bawah,
 * interaksi dengan NPC/barang/papan/stasiun, partikel, dan label wilayah.
 */

import { canPlayerAct, collectItem, readBoard, talkTo, useStation } from '../core/actions';
import { itemColor, itemIcon, village } from '../core/data';
import { getPendingPosition } from '../core/save';
import { hasFlag, notify, setFlag, showArea, state } from '../core/store';
import type { BoardData, NpcData, PickupData, PropData, StationData } from '../core/villageTypes';
import type { Rect, Vec } from '../core/types';
import { drawCharacter } from './character';
import { bubble, box, boxBorder, ellipse, line, ring, type Ctx } from './draw';
import { drawGround } from './ground';
import { alpha, C, mix } from './palette';
import { drawGlow, drawProp } from './props';
import * as audio from '../core/audio';

const PLAYER_SPEED = 172;
const ACCEL = 1500;
const FRICTION = 2000;
const PLAYER_HALF_W = 10;
const PLAYER_HALF_H = 14;
const REACH = 44; // radius area interaksi (sama dengan Player.tscn)

type EntityKind = 'npc' | 'pickup' | 'board' | 'station';

interface WorldEntity {
  id: string;
  kind: EntityKind;
  x: number;
  y: number;
  radius: number;
  prompt: string;
  data: NpcData | PickupData | BoardData | StationData;
  // khusus NPC
  isVillager?: boolean;
  home?: Vec;
  facing?: Vec;
  paletteId?: string;
  wanderIndex?: number;
  wanderTimer?: number;
  wanderPoints?: Vec[];
  wanderPause?: number;
  phase?: number;
  speedRatio?: number;
  gatherPosition?: Vec | null;
  render?: Renderable;
  altQuest?: string;
  altPosition?: Vec | null;
}

/** Satu item gambar dengan kotak batasnya, dihitung sekali lalu dipakai ulang. */
interface ViewBounds {
  minX: number;
  minY: number;
  maxX: number;
  maxY: number;
}

interface Renderable {
  y: number;
  minX: number;
  maxX: number;
  minY: number;
  maxY: number;
  draw: () => void;
}

interface Particle {
  x: number;
  y: number;
  vx: number;
  vy: number;
  life: number;
  max: number;
  size: number;
  color: string;
  kind: 'dot' | 'ring' | 'leaf' | 'firefly';
  spin?: number;
}

export class WorldEngine {
  private canvas: HTMLCanvasElement;
  private ctx: Ctx;
  private raf = 0;
  private last = 0;
  private time = 0;
  private dpr = 1;
  private scale = 2;
  private viewW = 800;
  private viewH = 450;

  private player = { x: village.spawn.x, y: village.spawn.y, vx: 0, vy: 0, fx: 0, fy: 1, phase: 0 };
  private cam = { x: village.spawn.x, y: village.spawn.y, ready: false };
  private keys = new Set<string>();
  private entities: WorldEntity[] = [];
  private props: PropData[] = [];
  private solids: Rect[] = [];
  private particles: Particle[] = [];
  private insideZones = new Set<string>();
  private focus: WorldEntity | null = null;
  private stepTimer = 0.3;
  private stepAlt = false;
  private leafTimer = 0;
  private fireflyTimer = 0;
  private destroyed = false;
  private renderables: Renderable[] = [];
  private visible: Renderable[] = [];
  private playerRenderable: Renderable = {
    y: 0,
    minX: 0,
    maxX: 0,
    minY: 0,
    maxY: 0,
    draw: () => undefined,
  };

  constructor(canvas: HTMLCanvasElement) {
    this.canvas = canvas;
    const context = canvas.getContext('2d');
    if (!context) throw new Error('Canvas 2D tidak tersedia di peramban ini.');
    this.ctx = context;
    this.buildWorld();
    this.resize();
  }

  // --- Persiapan -----------------------------------------------------------

  private buildWorld(): void {
    this.solids = [];
    for (const prop of village.props) {
      this.props.push(prop);
      if (prop.collision) this.solids.push(prop.collision);
    }
    for (const blocker of village.blockers) {
      this.solids.push({ x: blocker.x - blocker.w / 2, y: blocker.y - blocker.h / 2, w: blocker.w, h: blocker.h });
    }

    this.entities = [];
    for (const npc of village.npcs) {
      this.entities.push({
        id: npc.id,
        kind: 'npc',
        x: npc.x,
        y: npc.y,
        radius: 36,
        prompt: `Bicara dengan ${npc.display_name}`,
        data: npc,
        isVillager: npc.kind === 'villager',
        home: { x: npc.x, y: npc.y },
        facing: { x: npc.start_facing.x, y: npc.start_facing.y },
        paletteId: npc.palette_id,
        wanderIndex: 0,
        wanderTimer: Math.random() * 1.5,
        wanderPoints: npc.wander_points,
        wanderPause: npc.wander_pause,
        phase: Math.random() * 4,
        speedRatio: 0,
        gatherPosition: npc.gather_position,
        altQuest: npc.alt_quest,
        altPosition: npc.alt_position,
      });
    }
    for (const pickup of village.pickups) {
      if (pickup.flag_id && hasFlag(pickup.flag_id)) continue;
      this.entities.push({
        id: pickup.id,
        kind: 'pickup',
        x: pickup.x,
        y: pickup.y,
        radius: 34,
        prompt: `Ambil ${pickup.item_id}`,
        data: pickup,
      });
    }
    for (const board of village.boards) {
      this.entities.push({
        id: board.id,
        kind: 'board',
        x: board.x,
        y: board.y,
        radius: 40,
        prompt: board.prompt || 'Baca',
        data: board,
      });
    }
    for (const station of village.stations) {
      this.entities.push({
        id: station.id,
        kind: 'station',
        x: station.x,
        y: station.y,
        radius: 44,
        prompt: station.prompt || 'Susun perlengkapan',
        data: station,
      });
    }

    this.applyStoryPositions();
    const pending = getPendingPosition();
    if (pending) {
      this.player.x = pending.x;
      this.player.y = pending.y;
    } else {
      this.player.x = village.spawn.x;
      this.player.y = village.spawn.y;
    }
    this.cam.x = this.player.x;
    this.cam.y = this.player.y;
  }

  /** NPC berpindah mengikuti cerita (posisi kumpul / posisi quest khusus). */
  private applyStoryPositions(): void {
    const eventReady = hasFlag('event_ready');
    for (const entity of this.entities) {
      if (entity.kind !== 'npc' || !entity.gatherPosition) continue;
      if (eventReady) {
        entity.x = entity.gatherPosition.x;
        entity.y = entity.gatherPosition.y;
        entity.home = { ...entity.gatherPosition };
        entity.wanderPoints = [];
      } else if (entity.altQuest && entity.altPosition) {
        // Posisi cadangan dipakai saat quest terkait aktif (lihat Npc.gd).
        const alt = { x: entity.altPosition.x, y: entity.altPosition.y };
        entity.home = { ...alt };
        entity.x = alt.x;
        entity.y = alt.y;
      }
    }
    this.buildRenderables();
  }

  /** Menyiapkan daftar gambar sekali saja; kotak batas dipakai untuk menyaring
   *  properti yang berada di luar layar supaya gambar tetap ringan. */
  private buildRenderables(): void {
    this.renderables = [];
    for (const prop of this.props) {
      this.renderables.push({
        y: prop.y,
        minX: prop.x - prop.w,
        maxX: prop.x + prop.w,
        minY: prop.y - prop.h * 1.8,
        maxY: prop.y + prop.h * 0.3,
        draw: () => this.drawPropEntity(prop),
      });
    }
    for (const entity of this.entities) {
      const item: Renderable = {
        y: entity.y,
        minX: entity.x - entity.radius - 60,
        maxX: entity.x + entity.radius + 60,
        minY: entity.y - 90,
        maxY: entity.y + 24,
        draw: () => this.drawEntity(entity),
      };
      entity.render = item;
      this.renderables.push(item);
    }
    this.playerRenderable = {
      y: this.player.y,
      minX: this.player.x - 40,
      maxX: this.player.x + 40,
      minY: this.player.y - 90,
      maxY: this.player.y + 10,
      draw: () =>
        drawCharacter(this.ctx, 'raka', {
          x: this.player.x,
          y: this.player.y,
          facingX: this.player.fx,
          facingY: this.player.fy,
          speedRatio: Math.min(1, Math.hypot(this.player.vx, this.player.vy) / PLAYER_SPEED),
          phase: this.player.phase,
        }),
    };
    this.renderables.push(this.playerRenderable);
  }

  /** Kotak batas properti tetap; hanya NPC dan Raka yang bergerak. */
  private updateRenderableBounds(): void {
    for (const entity of this.entities) {
      const item = entity.render;
      if (!item) continue;
      item.y = entity.y;
      item.minX = entity.x - entity.radius - 60;
      item.maxX = entity.x + entity.radius + 60;
      item.minY = entity.y - 90;
      item.maxY = entity.y + 24;
    }
    const player = this.playerRenderable;
    player.y = this.player.y;
    player.minX = this.player.x - 40;
    player.maxX = this.player.x + 40;
    player.minY = this.player.y - 90;
    player.maxY = this.player.y + 10;
  }

  // --- Daur hidup ----------------------------------------------------------

  start(): void {
    this.last = performance.now();
    const loop = (now: number) => {
      if (this.destroyed) return;
      // Dibatasi 0..50 ms: jam peramban bisa melompat atau mundur.
      const dt = clamp((now - this.last) / 1000, 0, 0.05);
      this.last = now;
      this.update(dt);
      this.draw();
      this.raf = window.requestAnimationFrame(loop);
    };
    this.raf = window.requestAnimationFrame(loop);
    window.addEventListener('keydown', this.onKeyDown);
    window.addEventListener('keyup', this.onKeyUp);
    window.addEventListener('resize', this.resize);
  }

  stop(): void {
    this.destroyed = true;
    window.cancelAnimationFrame(this.raf);
    window.removeEventListener('keydown', this.onKeyDown);
    window.removeEventListener('keyup', this.onKeyUp);
    window.removeEventListener('resize', this.resize);
    this.keys.clear();
    if (state.prompt !== null) {
      state.prompt = null;
      notify();
    }
  }

  resize = (): void => {
    this.dpr = Math.min(2, window.devicePixelRatio || 1);
    const rect = this.canvas.getBoundingClientRect();
    const cssW = Math.max(320, rect.width || window.innerWidth);
    const cssH = Math.max(240, rect.height || window.innerHeight);
    this.canvas.width = Math.floor(cssW * this.dpr);
    this.canvas.height = Math.floor(cssH * this.dpr);
    this.viewW = cssW;
    this.viewH = cssH;
    // Skala adaptif: sekitar 700 piksel dunia terlihat, sama seperti zoom 1.6
    // pada viewport 1280x720 versi Godot.
    this.scale = Math.min(2.6, Math.max(1.6, cssW / 700));
  };

  private onKeyDown = (event: KeyboardEvent): void => {
    if (event.repeat) return;
    const code = event.code;
    if (MOVE_KEYS.has(code) || code === 'KeyE') {
      this.keys.add(code);
      if (code === 'KeyE') this.interact();
      if (MOVE_KEYS.has(code)) event.preventDefault();
    }
  };

  private onKeyUp = (event: KeyboardEvent): void => {
    this.keys.delete(event.code);
  };

  // --- Perbarui ------------------------------------------------------------

  private update(dt: number): void {
    this.time += dt;
    const act = canPlayerAct();
    if (state.gameStarted && !state.paused && state.dialogue === null) {
      state.playTime += dt;
    }

    if (act) {
      const input = this.readInput();
      const targetX = input.x * PLAYER_SPEED;
      const targetY = input.y * PLAYER_SPEED;
      if (input.x !== 0 || input.y !== 0) {
        this.player.vx = approach(this.player.vx, targetX, ACCEL * dt);
        this.player.vy = approach(this.player.vy, targetY, ACCEL * dt);
        this.player.fx = input.x;
        this.player.fy = input.y;
      } else {
        this.player.vx = approach(this.player.vx, 0, FRICTION * dt);
        this.player.vy = approach(this.player.vy, 0, FRICTION * dt);
      }
    } else {
      this.player.vx = approach(this.player.vx, 0, FRICTION * dt);
      this.player.vy = approach(this.player.vy, 0, FRICTION * dt);
    }

    this.movePlayer(this.player.vx * dt, this.player.vy * dt);

    const speed = Math.hypot(this.player.vx, this.player.vy);
    const ratio = Math.min(1, speed / PLAYER_SPEED);
    if (ratio > 0.06) {
      this.player.phase += dt * (0.6 + ratio);
      this.stepTimer -= dt * (0.7 + ratio);
      if (this.stepTimer <= 0 && act) {
        this.stepTimer = 0.42;
        this.stepAlt = !this.stepAlt;
        audio.playSfx(this.stepAlt ? 'step1' : 'step2', 0.94 + Math.random() * 0.14);
      }
    } else {
      this.stepTimer = Math.min(this.stepTimer, 0.18);
    }
    this.updateNpcs(dt, ratio);
    this.updateCamera(dt);
    this.updateZones();
    this.updateFocus();
    this.updateParticles(dt);
    this.spawnAmbient(dt);
  }

  private readInput(): Vec {
    let x = 0;
    let y = 0;
    if (this.keys.has('KeyA') || this.keys.has('ArrowLeft')) x -= 1;
    if (this.keys.has('KeyD') || this.keys.has('ArrowRight')) x += 1;
    if (this.keys.has('KeyW') || this.keys.has('ArrowUp')) y -= 1;
    if (this.keys.has('KeyS') || this.keys.has('ArrowDown')) y += 1;
    if (x !== 0 && y !== 0) {
      const inv = 1 / Math.SQRT2;
      x *= inv;
      y *= inv;
    }
    return { x, y };
  }

  private movePlayer(dx: number, dy: number): void {
    const map = village.map;
    const margin = 30;
    // Kotak Raka: 20x14 dengan titik tengah 7 px di atas telapak kaki,
    // sama dengan CollisionShape2D pada scenes/player/Player.tscn.
    const footTop = (y: number): number => y - PLAYER_HALF_H;
    // sumbu X
    const nx = this.player.x + dx;
    const boxX: Rect = { x: nx - PLAYER_HALF_W, y: footTop(this.player.y), w: PLAYER_HALF_W * 2, h: PLAYER_HALF_H };
    if (!this.hits(boxX)) this.player.x = nx;
    else this.player.vx = 0;
    // sumbu Y
    const ny = this.player.y + dy;
    const boxY: Rect = { x: this.player.x - PLAYER_HALF_W, y: footTop(ny), w: PLAYER_HALF_W * 2, h: PLAYER_HALF_H };
    if (!this.hits(boxY)) this.player.y = ny;
    else this.player.vy = 0;
    // tidak boleh keluar peta
    this.player.x = Math.min(Math.max(this.player.x, map.x + margin), map.x + map.w - margin);
    this.player.y = Math.min(Math.max(this.player.y, map.y + margin), map.y + map.h - margin);
  }

  private hits(rect: Rect): boolean {
    for (const solid of this.solids) {
      if (
        rect.x < solid.x + solid.w &&
        rect.x + rect.w > solid.x &&
        rect.y < solid.y + solid.h &&
        rect.y + rect.h > solid.y
      ) {
        return true;
      }
    }
    return false;
  }

  private updateNpcs(dt: number, playerRatio: number): void {
    void playerRatio;
    const eventReady = hasFlag('event_ready');
    for (const entity of this.entities) {
      if (entity.kind !== 'npc') continue;
      const npc = entity.data as NpcData;
      if (eventReady && entity.gatherPosition) {
        const dx = entity.gatherPosition.x - entity.x;
        const dy = entity.gatherPosition.y - entity.y;
        if (Math.hypot(dx, dy) < 3) {
          entity.speedRatio = 0;
          entity.facing = { x: 0, y: 1 };
        } else {
          const step = Math.min(1, dt * 2.4);
          entity.x += dx * step;
          entity.y += dy * step;
          entity.facing = normalize(dx, dy);
          entity.speedRatio = 0.8;
          entity.phase = (entity.phase ?? 0) + dt * 5;
        }
        continue;
      }
      if (npc.alt_quest && entity.altPosition && state.quests[npc.alt_quest]) {
        // sudah ditangani applyStoryPositions saat masuk layar
      }
      const points = entity.wanderPoints ?? [];
      if (points.length === 0 || !entity.home) {
        entity.speedRatio = 0;
        this.facePlayer(entity);
        continue;
      }
      if ((entity.wanderTimer ?? 0) > 0) {
        entity.wanderTimer = (entity.wanderTimer ?? 0) - dt;
        entity.speedRatio = 0;
        this.facePlayer(entity);
        continue;
      }
      const goal = {
        x: entity.home.x + points[entity.wanderIndex ?? 0].x,
        y: entity.home.y + points[entity.wanderIndex ?? 0].y,
      };
      const dx = goal.x - entity.x;
      const dy = goal.y - entity.y;
      const distance = Math.hypot(dx, dy);
      if (distance < 4) {
        entity.wanderIndex = ((entity.wanderIndex ?? 0) + 1) % points.length;
        entity.wanderTimer = entity.wanderPause ?? 1.8;
        entity.speedRatio = 0;
        continue;
      }
      const speed = 26 * dt;
      entity.x += (dx / distance) * speed;
      entity.y += (dy / distance) * speed;
      entity.facing = { x: dx / distance, y: dy / distance };
      entity.speedRatio = 0.7;
      entity.phase = (entity.phase ?? 0) + dt * 5;
    }
  }

  private facePlayer(entity: WorldEntity): void {
    const dx = this.player.x - entity.x;
    const dy = this.player.y - entity.y;
    if (Math.hypot(dx, dy) <= 78) entity.facing = normalize(dx, dy);
  }

  /** Kotak wilayah yang terlihat di layar, dalam koordinat dunia. */
  private viewBounds(margin: number): ViewBounds {
    const halfW = this.viewW / 2 / this.scale;
    const halfH = this.viewH / 2 / this.scale;
    return {
      minX: this.cam.x - halfW - margin,
      minY: this.cam.y - halfH - margin,
      maxX: this.cam.x + halfW + margin,
      maxY: this.cam.y + halfH + margin,
    };
  }

  private updateCamera(dt: number): void {
    const targetX = this.player.x + this.player.fx * 14;
    const targetY = this.player.y - PLAYER_HALF_H + this.player.fy * 10;
    if (!this.cam.ready) {
      this.cam.x = targetX;
      this.cam.y = targetY;
      this.cam.ready = true;
    } else {
      const t = Math.min(1, dt * 6.5);
      this.cam.x += (targetX - this.cam.x) * t;
      this.cam.y += (targetY - this.cam.y) * t;
    }
    const halfW = this.viewW / 2 / this.scale;
    const halfH = this.viewH / 2 / this.scale;
    const map = village.map;
    this.cam.x = halfW * 2 > map.w ? map.x + map.w / 2 : clamp(this.cam.x, map.x + halfW, map.x + map.w - halfW);
    this.cam.y = halfH * 2 > map.h ? map.y + map.h / 2 : clamp(this.cam.y, map.y + halfH, map.y + map.h - halfH);
  }

  private updateZones(): void {
    for (const zone of village.zones) {
      const inside =
        this.player.x >= zone.rect.x &&
        this.player.x <= zone.rect.x + zone.rect.w &&
        this.player.y >= zone.rect.y &&
        this.player.y <= zone.rect.y + zone.rect.h;
      if (inside && !this.insideZones.has(zone.id)) {
        this.insideZones.add(zone.id);
        if (zone.flag) setFlag(zone.flag, true);
        showArea(zone.title, zone.subtitle);
      } else if (!inside) {
        this.insideZones.delete(zone.id);
      }
    }
  }

  private updateFocus(): void {
    let best: WorldEntity | null = null;
    let bestDistance = Infinity;
    const act = canPlayerAct();
    const centerY = this.player.y - 10;
    for (const entity of this.entities) {
      const distance = Math.hypot(entity.x - this.player.x, entity.y - centerY);
      if (distance <= REACH + entity.radius && distance < bestDistance) {
        bestDistance = distance;
        best = entity;
      }
    }
    const next = act ? best : null;
    if (next === this.focus) return;
    this.focus = next;
    const prompt = next ? next.prompt : null;
    if (state.prompt !== prompt) {
      state.prompt = prompt;
      notify();
    }
  }

  private interact(): void {
    if (!canPlayerAct() || !this.focus) return;
    const entity = this.focus;
    switch (entity.kind) {
      case 'npc': {
        const npc = entity.data as NpcData;
        audio.playSfx('talk', -4);
        talkTo(npc);
        break;
      }
      case 'pickup': {
        const pickup = entity.data as PickupData;
        collectItem(pickup);
        this.burst(entity.x, entity.y - 20, itemColor(pickup.item_id), 18, 26);
        this.ringPop(entity.x, entity.y - 20, C.goldPale, 46);
        this.entities = this.entities.filter((item) => item !== entity);
        this.focus = null;
        state.prompt = null;
        notify();
        break;
      }
      case 'board': {
        const board = entity.data as BoardData;
        readBoard(board);
        break;
      }
      case 'station': {
        const station = entity.data as StationData;
        useStation(
          ['bambu', 'tali', 'papan_kayu', 'kain_pola'],
          'prep',
          'panggung',
          'persiapan_kurang',
        );
        void station;
        break;
      }
      default:
        break;
    }
    void entity;
  }

  // --- Partikel ------------------------------------------------------------

  burst(x: number, y: number, color: string, count: number, radius: number): void {
    for (let i = 0; i < count; i += 1) {
      const angle = (i / count) * Math.PI * 2 + Math.random() * 0.5;
      const speed = radius * (0.6 + Math.random() * 0.8);
      this.particles.push({
        x,
        y,
        vx: Math.cos(angle) * speed,
        vy: Math.sin(angle) * speed - 12,
        life: 0.7,
        max: 0.7,
        size: 3 + Math.random() * 2,
        color,
        kind: 'dot',
      });
    }
  }

  ringPop(x: number, y: number, color: string, radius: number): void {
    this.particles.push({
      x,
      y,
      vx: 0,
      vy: 0,
      life: 0.5,
      max: 0.5,
      size: radius,
      color,
      kind: 'ring',
    });
  }

  private updateParticles(dt: number): void {
    for (let i = this.particles.length - 1; i >= 0; i -= 1) {
      const particle = this.particles[i];
      particle.life -= dt;
      if (particle.life <= 0) {
        this.particles.splice(i, 1);
        continue;
      }
      particle.x += particle.vx * dt;
      particle.y += particle.vy * dt;
      if (particle.kind === 'dot') {
        particle.vy += 60 * dt;
        particle.vx *= 0.97;
      } else if (particle.kind === 'leaf') {
        particle.vx += Math.sin(this.time * 1.6 + particle.y * 0.02) * 6 * dt;
        particle.spin = (particle.spin ?? 0) + dt * 2;
      } else if (particle.kind === 'firefly') {
        particle.vx = Math.sin(this.time * 1.2 + particle.y * 0.05) * 8;
        particle.vy = Math.cos(this.time * 0.9 + particle.x * 0.04) * 6;
      }
    }
  }

  private spawnAmbient(dt: number): void {
    // daun yang melayang
    this.leafTimer -= dt;
    if (this.leafTimer <= 0) {
      this.leafTimer = 0.5 + Math.random() * 0.6;
      const x = this.cam.x + (Math.random() - 0.3) * this.viewW;
      const y = village.map.y + Math.random() * village.map.h * 0.6;
      this.particles.push({
        x,
        y,
        vx: 14 + Math.random() * 10,
        vy: 10 + Math.random() * 6,
        life: 7,
        max: 7,
        size: 5 + Math.random() * 3,
        color: Math.random() > 0.5 ? C.leaf : C.leafLight,
        kind: 'leaf',
        spin: Math.random() * 6,
      });
    }
    // kunang-kunang setelah acara siap
    if (hasFlag('event_ready')) {
      this.fireflyTimer -= dt;
      if (this.fireflyTimer <= 0) {
        this.fireflyTimer = 0.25;
        this.particles.push({
          x: 1500 + (Math.random() - 0.5) * 1200,
          y: 900 + (Math.random() - 0.5) * 800,
          vx: 0,
          vy: 0,
          life: 4,
          max: 4,
          size: 2.4 + Math.random() * 1.6,
          color: C.lantern,
          kind: 'firefly',
        });
      }
    }
  }

  // --- Gambar --------------------------------------------------------------

  private draw(): void {
    const ctx = this.ctx;
    ctx.setTransform(1, 0, 0, 1, 0, 0);
    ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
    ctx.scale(this.dpr, this.dpr);
    ctx.fillStyle = C.grassDark;
    ctx.fillRect(0, 0, this.viewW, this.viewH);
    ctx.save();
    ctx.scale(this.scale, this.scale);
    ctx.translate(-(this.cam.x - this.viewW / 2 / this.scale), -(this.cam.y - this.viewH / 2 / this.scale));

    drawGround(ctx, village);
    this.drawGlows();

    // Hanya yang terlihat di layar yang digambar, lalu diurutkan atas-bawah.
    this.updateRenderableBounds();
    const view = this.viewBounds(180);
    const visible = this.visible;
    visible.length = 0;
    for (const item of this.renderables) {
      if (item.maxX < view.minX || item.minX > view.maxX) continue;
      if (item.maxY < view.minY || item.minY > view.maxY) continue;
      visible.push(item);
    }
    visible.sort((a, b) => a.y - b.y);
    for (const item of visible) item.draw();

    this.drawParticles();
    this.drawFocusBubble();

    if (hasFlag('event_ready')) {
      ctx.fillStyle = alpha(C.nightSky, 0.18);
      ctx.fillRect(this.cam.x - this.viewW, this.cam.y - this.viewH, this.viewW * 2, this.viewH * 2);
    }

    ctx.restore();
  }

  private drawGlows(): void {
    const ctx = this.ctx;
    const eventReady = hasFlag('event_ready');
    const view = this.viewBounds(400);
    for (const prop of this.props) {
      const strength = glowOf(prop, eventReady);
      if (strength <= 0.02) continue;
      if (prop.x + prop.h * 3 < view.minX || prop.x - prop.h * 3 > view.maxX) continue;
      if (prop.y + prop.h * 3 < view.minY || prop.y - prop.h * 3 > view.maxY) continue;
      const radius = prop.kind === 'fire_pit' ? prop.h * 5 : prop.h * 2.6;
      drawGlow(ctx, prop.x, prop.y - prop.h * 0.8, radius, prop.kind === 'fire_pit' ? C.fire : C.lantern, strength);
    }
    const station = this.entities.find((entity) => entity.kind === 'station');
    if (station && eventReady) drawGlow(ctx, station.x, station.y - 30, 150, C.lantern, 0.7);
  }

  private drawPropEntity(prop: PropData): void {
    // Properti digambar pada titik asal lokal, jadi harus dipindahkan dulu ke
    // posisinya di peta (sama seperti Node2D.position pada versi Godot).
    const ctx = this.ctx;
    ctx.save();
    ctx.translate(prop.x, prop.y);
    drawProp(
      ctx,
      {
        kind: prop.kind,
        w: prop.w,
        h: prop.h,
        variant: prop.variant,
        sway: prop.sway,
        glow: glowOf(prop, hasFlag('event_ready')),
      },
      this.time,
    );
    ctx.restore();
  }

  private drawEntity(entity: WorldEntity): void {
    const ctx = this.ctx;
    switch (entity.kind) {
      case 'npc': {
        drawCharacter(ctx, entity.paletteId ?? 'raka', {
          x: entity.x,
          y: entity.y,
          facingX: entity.facing?.x ?? 0,
          facingY: entity.facing?.y ?? 1,
          speedRatio: entity.speedRatio ?? 0,
          phase: entity.phase ?? 0,
        });
        break;
      }
      case 'pickup': {
        const pickup = entity.data as PickupData;
        const bob = Math.sin(this.time * 2.2) * 3;
        drawGlow(ctx, entity.x, entity.y - 18, 42, itemColor(pickup.item_id), 0.55);
        ring(ctx, entity.x, entity.y - 12, 22, 9, alpha(C.gold, 0.45), 2, 26);
        drawItemIcon(ctx, itemIcon(pickup.item_id), entity.x, entity.y - 20 + bob, itemColor(pickup.item_id));
        break;
      }
      case 'board': {
        const board = entity.data as BoardData;
        drawBoardProp(ctx, board, this.time);
        break;
      }
      case 'station': {
        drawStation(ctx, this.time);
        break;
      }
      default:
        break;
    }
  }

  private drawParticles(): void {
    const ctx = this.ctx;
    for (const particle of this.particles) {
      const t = Math.max(0, particle.life / particle.max);
      if (particle.kind === 'ring') {
        const radius = particle.size * (1.15 - t * 0.55);
        ring(ctx, particle.x, particle.y, radius, radius * 0.5, alpha(particle.color, 0.6 * t), 3, 30);
        continue;
      }
      if (particle.kind === 'leaf') {
        ctx.save();
        ctx.translate(particle.x, particle.y);
        ctx.rotate(particle.spin ?? 0);
        ellipse(ctx, 0, 0, particle.size, particle.size * 0.5, alpha(particle.color, 0.85 * Math.min(1, t * 3)));
        ctx.restore();
        continue;
      }
      if (particle.kind === 'firefly') {
        const pulse = 0.5 + Math.sin(this.time * 4 + particle.x) * 0.5;
        drawGlow(ctx, particle.x, particle.y, 14, particle.color, pulse * t);
        continue;
      }
      ellipse(ctx, particle.x, particle.y, particle.size, particle.size, alpha(particle.color, t));
    }
  }

  private drawFocusBubble(): void {
    if (!this.focus || !canPlayerAct()) return;
    bubble(this.ctx, this.focus.x, this.focus.y - 58, this.focus.prompt, 'E', 11);
  }
}

// --- Fungsi bantu ----------------------------------------------------------

const MOVE_KEYS = new Set(['KeyW', 'KeyA', 'KeyS', 'KeyD', 'ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight']);

function approach(value: number, target: number, amount: number): number {
  if (value < target) return Math.min(target, value + amount);
  if (value > target) return Math.max(target, value - amount);
  return value;
}

function clamp(value: number, low: number, high: number): number {
  return Math.min(Math.max(value, low), high);
}

function normalize(x: number, y: number): Vec {
  const length = Math.hypot(x, y);
  if (length < 0.0001) return { x: 0, y: 1 };
  return { x: x / length, y: y / length };
}

function glowOf(prop: PropData, eventReady: boolean): number {
  if (prop.kind === 'fire_pit') return eventReady ? 1 : 0.45;
  if (prop.kind === 'lamp' || prop.kind === 'stage') return eventReady ? 1 : prop.glow;
  return prop.glow;
}

function drawItemIcon(ctx: Ctx, icon: string, x: number, y: number, color: string): void {
  ctx.save();
  ctx.translate(x, y);
  switch (icon) {
    case 'rope': {
      ring(ctx, 0, 0, 13, 10, mix(color, C.woodDark, 0.35), 4, 26);
      ring(ctx, 0, 0, 8, 6, mix(color, C.cream, 0.3), 2.6, 22);
      break;
    }
    case 'plank': {
      box(ctx, -16, -6, 32, 12, color, 3);
      line(ctx, -16, 0, 16, 0, alpha(C.woodDark, 0.6), 1.6);
      line(ctx, -16, -3, 16, -3, alpha(C.cream, 0.25), 1.4);
      break;
    }
    case 'cloth': {
      box(ctx, -16, -12, 32, 24, color, 4);
      for (let i = 0; i < 3; i += 1) {
        line(ctx, -16, -8 + i * 7, 16, -8 + i * 7, alpha(C.gold, 0.7), 2);
      }
      for (let i = 0; i < 3; i += 1) {
        line(ctx, -11 + i * 11, -12, -11 + i * 11, 12, alpha(C.gold, 0.45), 1.6);
      }
      break;
    }
    case 'bamboo':
    default: {
      for (const offset of [-6, 0, 6]) {
        line(ctx, offset, 14, offset + 2, -14, color, 5);
        line(ctx, offset, 14, offset + 2, -14, mix(color, C.cream, 0.35), 2.4);
        for (const node of [-6, 0, 6]) {
          line(ctx, offset - 4, node, offset + 6, node - 1, alpha(C.bambooDark, 0.85), 2);
        }
      }
      break;
    }
  }
  ctx.restore();
}

function drawBoardProp(ctx: Ctx, board: BoardData, time: number): void {
  const glow = 0.35 + Math.sin(time * 2) * 0.1;
  line(ctx, board.x, board.y, board.x, board.y - 30, C.woodDark, 5);
  boxBorder(ctx, board.x - 22, board.y - 66, 44, 40, C.woodLight, C.woodDark, 2, 4);
  for (let i = 0; i < 3; i += 1) {
    line(ctx, board.x - 15, board.y - 56 + i * 10, board.x + 15, board.y - 56 + i * 10, alpha(C.woodDark, 0.55), 1.6);
  }
  ellipse(ctx, board.x + 16, board.y - 62, 3, 3, alpha(C.gold, glow));
}

function drawStation(ctx: Ctx, time: number): void {
  const x = village.stations[0].x;
  const y = village.stations[0].y;
  const pulse = 0.5 + Math.sin(time * 1.8) * 0.2;
  // meja panjang tempat perlengkapan disusun
  box(ctx, x - 46, y - 26, 92, 10, C.woodLight, 3);
  box(ctx, x - 42, y - 16, 6, 16, C.woodDark, 2);
  box(ctx, x + 36, y - 16, 6, 16, C.woodDark, 2);
  box(ctx, x - 34, y - 40, 24, 14, mix(C.bamboo, C.cream, 0.3), 3);
  box(ctx, x + 4, y - 38, 20, 12, C.fabricRed, 3);
  ring(ctx, x, y - 6, 40, 14, alpha(C.gold, 0.35 * pulse + 0.2), 2, 30);
}
