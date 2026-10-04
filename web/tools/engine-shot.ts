/**
 * Tangkapan layar dari mesin dunia asli (WorldEngine), bukan tiruan.
 *
 * Alat pengembangan saja (butuh @napi-rs/canvas dan jsdom):
 *   cd web && npx tsx tools/engine-shot.ts
 */

import { mkdirSync, writeFileSync } from 'node:fs';
import { createCanvas } from '@napi-rs/canvas';
import { JSDOM } from 'jsdom';

// --- Lingkungan peramban tiruan --------------------------------------------

const dom = new JSDOM('<!doctype html><html><body></body></html>', {
  url: 'https://preview.local/',
  pretendToBeVisual: true,
});
const globals = globalThis as unknown as Record<string, unknown>;
globals.window = dom.window;
globals.document = dom.window.document;
globals.localStorage = dom.window.localStorage;

let clock = 0;
Object.defineProperty(dom.window.performance, 'now', { value: () => clock });
Object.defineProperty(globalThis, 'performance', { value: { now: () => clock }, configurable: true });
Object.defineProperty(dom.window, 'devicePixelRatio', { value: 1 });

const frames: FrameRequestCallback[] = [];
Object.assign(dom.window, {
  requestAnimationFrame: (cb: FrameRequestCallback) => {
    frames.push(cb);
    return frames.length;
  },
  cancelAnimationFrame: () => undefined,
});

// --- Modul permainan --------------------------------------------------------

const actions = await import('../src/core/actions');
const quests = await import('../src/core/quests');
const { state } = await import('../src/core/store');
const { village, questOrder } = await import('../src/core/data');
const { WorldEngine } = await import('../src/game/engine');

mkdirSync('.shots', { recursive: true });

interface Bridge {
  canvas: unknown;
  flush: () => void;
}

/** Menyambungkan Canvas sungguhan ke mesin dunia. */
function makeBridge(width: number, height: number): Bridge {
  const canvas = createCanvas(width, height);
  const ctx = canvas.getContext('2d');
  const fake = {
    width,
    height,
    getContext: () => ctx,
    getBoundingClientRect: () => ({ x: 0, y: 0, width, height, top: 0, left: 0, right: width, bottom: height }),
    addEventListener: () => undefined,
    removeEventListener: () => undefined,
  };
  return {
    canvas: fake,
    flush: () => writeFileSync('.shots/', new Uint8Array(), { flag: 'w' }),
  };
}

function step(times: number): void {
  for (let i = 0; i < times; i += 1) {
    clock += 1000 / 60;
    const pending = frames.splice(0, frames.length);
    for (const cb of pending) cb(clock);
  }
}

function save(name: string, engine: { ctx: CanvasRenderingContext2D }, width: number, height: number): void {
  const canvas = (engine.ctx as unknown as { canvas: unknown }).canvas as { toBuffer: (type: string) => Uint8Array };
  const buffer = canvas.toBuffer('image/png');
  writeFileSync(`.shots/${name}.png`, buffer);
  console.log(`  ${name}.png (${width}x${height}, ${buffer.length} byte)`);
}

async function shoot(name: string, place: (engine: unknown) => void, night = false): Promise<void> {
  const width = 1280;
  const height = 720;
  const canvas = createCanvas(width, height);
  const ctx = canvas.getContext('2d');
  const fake = {
    width,
    height,
    getContext: () => ctx,
    getBoundingClientRect: () => ({ x: 0, y: 0, width, height, top: 0, left: 0, right: width, bottom: height }),
    addEventListener: () => undefined,
    removeEventListener: () => undefined,
  };
  if (night) {
    for (const id of questOrder) {
      quests.startQuest(id);
      for (const objective of state.quests[id]?.objectives ?? []) {
        quests.advanceObjective(id, objective.id, objective.count);
      }
      quests.completeQuest(id);
    }
    state.flags.event_ready = true;
  }
  const engine = new WorldEngine(fake as unknown as HTMLCanvasElement);
  engine.start();
  place(engine as unknown);
  step(90);
  const buffer = (canvas as unknown as { toBuffer: (type: string) => Uint8Array }).toBuffer('image/png');
  writeFileSync(`.shots/${name}.png`, buffer);
  console.log(`  ${name}.png (${width}x${height}, ${buffer.length} byte)`);
  engine.stop();
  step(2);
}

actions.newGame();
state.screen = 'village';
state.transitioning = false;
quests.startQuest('q_pulang');

console.log('tangkapan layar dari mesin asli:');
await shoot('engine_gerbang', () => undefined);
await shoot('engine_alun_alun', (engine) => {
  const world = engine as { player: { x: number; y: number } };
  world.player.x = 1450;
  world.player.y = 1080;
});
await shoot('engine_rumah', (engine) => {
  const world = engine as { player: { x: number; y: number } };
  world.player.x = 820;
  world.player.y = 1000;
});
await shoot('engine_bengkel', (engine) => {
  const world = engine as { player: { x: number; y: number } };
  world.player.x = 2400;
  world.player.y = 1000;
});
await shoot('engine_malam', (engine) => {
  const world = engine as { player: { x: number; y: number } };
  world.player.x = 2450;
  world.player.y = 1420;
}, true);
void village;
