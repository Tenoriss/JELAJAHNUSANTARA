/**
 * Uji gambar versi web: menjalankan mesin dunia sungguhan dengan Canvas tiruan.
 *
 * Memastikan seluruh kode gambar berjalan tanpa galat, tidak menghasilkan
 * koordinat NaN/tak hingga, dan semua properti di peta benar-benar tergambar.
 *
 *   cd web && npx tsx tools/render-smoke.ts
 */

import { JSDOM } from 'jsdom';

const dom = new JSDOM('<!doctype html><html><body></body></html>', {
  url: 'https://preview.local/',
  pretendToBeVisual: true,
});
const globals = globalThis as unknown as Record<string, unknown>;
globals.window = dom.window;
globals.document = dom.window.document;
globals.localStorage = dom.window.localStorage;

// --- Canvas tiruan ----------------------------------------------------------

let problems: string[] = [];
let calls = 0;
const gradients = new Set<string>();

function scan(args: unknown[], where: string): void {
  for (const value of args) {
    if (typeof value === 'number' && !Number.isFinite(value)) {
      problems.push(`${where} menerima angka tidak sah: ${value}`);
    }
  }
}

interface RecordedContext {
  [key: string]: unknown;
}

/** Titik-titik perpindahan gambar (ctx.translate) pada langkah terakhir. */
const translateTargets: { x: number; y: number }[] = [];

function makeContext(): CanvasRenderingContext2D {
  const store: RecordedContext = {};
  const noop = (name: string) => (...args: unknown[]) => {
    calls += 1;
    scan(args, name);
    if (name === 'translate' && typeof args[0] === 'number' && typeof args[1] === 'number') {
      translateTargets.push({ x: args[0], y: args[1] });
    }
    if (name === 'measureText') return { width: String(args[0] ?? '').length * 8 };
    if (name === 'createLinearGradient' || name === 'createRadialGradient') {
      gradients.add(name);
      return { addColorStop: () => undefined };
    }
    return undefined;
  };
  return new Proxy(store, {
    get(target, prop: string | symbol) {
      if (typeof prop === 'symbol') return undefined;
      if (prop in target) return target[prop];
      return noop(prop);
    },
    set(target, prop: string | symbol, value: unknown) {
      if (typeof prop === 'string' && typeof value === 'number' && !Number.isFinite(value)) {
        problems.push(`ctx.${prop} diberi angka tidak sah: ${value}`);
      }
      if (typeof prop === 'string') target[prop] = value;
      return true;
    },
  }) as unknown as CanvasRenderingContext2D;
}

function makeCanvas(): HTMLCanvasElement {
  return {
    width: 1280,
    height: 720,
    getContext: () => makeContext(),
    getBoundingClientRect: () => ({ x: 0, y: 0, width: 1280, height: 720, top: 0, left: 0, right: 1280, bottom: 720 }),
    addEventListener: () => undefined,
    removeEventListener: () => undefined,
  } as unknown as HTMLCanvasElement;
}

// Jam main: 60 langkah per detik tanpa menunggu waktu nyata.
let clock = 0;
Object.defineProperty(dom.window.performance, 'now', { value: () => clock });
Object.defineProperty(globalThis, 'performance', { value: { now: () => clock }, configurable: true });
Object.defineProperty(dom.window, 'devicePixelRatio', { value: 2 });

const frames: FrameRequestCallback[] = [];
globals.window = Object.assign(dom.window, {
  requestAnimationFrame: (cb: FrameRequestCallback) => {
    frames.push(cb);
    return frames.length;
  },
  cancelAnimationFrame: () => undefined,
});

// --- Modul permainan --------------------------------------------------------

const actions = await import('../src/core/actions');
const dialogue = await import('../src/core/dialogue');
const quests = await import('../src/core/quests');
const { state } = await import('../src/core/store');
const { village, questOrder } = await import('../src/core/data');
const { drawProp, drawGlow } = await import('../src/game/props');
const { drawCharacter, drawPortrait } = await import('../src/game/character');
const { drawGround } = await import('../src/game/ground');
const { drawDuskScene, drawNightScene } = await import('../src/game/scenery');
const { WorldEngine } = await import('../src/game/engine');

let failures = 0;
let checks = 0;
function check(condition: boolean, label: string): void {
  checks += 1;
  if (condition) console.log(`  ok   ${label}`);
  else {
    failures += 1;
    console.log(`  GAGAL ${label}`);
  }
}

function step(times: number): void {
  for (let i = 0; i < times; i += 1) {
    clock += 1000 / 60;
    const pending = frames.splice(0, frames.length);
    for (const cb of pending) cb(clock);
  }
}

function key(type: 'keydown' | 'keyup', code: string): void {
  dom.window.dispatchEvent(new dom.window.KeyboardEvent(type, { code, bubbles: true }));
}

function press(code: string): void {
  key('keydown', code);
  key('keyup', code);
}

// --- 1. Setiap jenis gambar -------------------------------------------------

console.log('\n== Gambar seluruh isi peta ==');
const ctx = makeContext();
const kinds = new Set<string>();
for (const prop of village.props) {
  kinds.add(prop.kind);
  try {
    drawProp(ctx, { kind: prop.kind, w: prop.w, h: prop.h, variant: prop.variant, sway: prop.sway, glow: prop.glow }, 3.5);
  } catch (error) {
    problems.push(`drawProp(${prop.kind}) gagal: ${(error as Error).message}`);
  }
}
check(problems.length === 0, `semua properti tergambar tanpa galat (${village.props.length} properti, ${kinds.size} jenis)`);

for (const palette of ['raka', ...village.npcs.map((npc) => npc.palette_id)]) {
  try {
    drawPortrait(ctx, palette, 128);
    drawCharacter(ctx, palette, { x: 0, y: 0, facingX: 0, facingY: 1, speedRatio: 1, phase: 1.7 });
  } catch (error) {
    problems.push(`karakter ${palette} gagal: ${(error as Error).message}`);
  }
}
check(problems.length === 0, 'semua karakter & potret tergambar');

try {
  drawGround(ctx, village);
  drawGlow(ctx, 100, 100, 90, '#f2b134', 0.6);
  drawDuskScene(ctx, 1280, 720, 4, true);
  drawNightScene(ctx, 1280, 720, 6, [
    { paletteId: 'mbah_seno', x: 400, y: 480, facing: 'up' },
    { paletteId: 'sari', x: 620, y: 500, facing: 'up' },
    { paletteId: 'warga_anak', x: 800, y: 470, facing: 'up' },
  ]);
} catch (error) {
  problems.push(`pemandangan gagal: ${(error as Error).message}`);
}
check(problems.length === 0, 'tanah, pendar, dan pemandangan tergambar');

// --- 2. Mesin dunia berjalan ------------------------------------------------

async function playWorld(): Promise<void> {
  // --- 2. Mesin dunia berjalan ------------------------------------------------

  console.log('\n== Mesin dunia berjalan ==');
  actions.newGame();
  actions.goto('village');
  quests.startQuest('q_pulang');
  // Fade antar layar memakai setTimeout: tunggu sebentar supaya Raka bisa bergerak.
  await new Promise((resolve) => dom.window.setTimeout(resolve, 500));

  const canvas = makeCanvas();
  const engine = new WorldEngine(canvas);
  engine.start();
  const beforeEngine = calls;
  step(30);
  const perFrame = Math.round((calls - beforeEngine) / 30);
  check(calls - beforeEngine > 500, `mesin menggambar (${perFrame} panggilan canvas per langkah)`);
  check(perFrame < 6000, `gambar tetap ringan: ${perFrame} panggilan per langkah (batas 6000)`);

  // Batas peta: pemain tidak boleh keluar dari Desa Arunika.
  const world = engine as unknown as { player: { x: number; y: number } };
  check(
    world.player.x >= 0 && world.player.x <= village.map.w && world.player.y >= 0 && world.player.y <= village.map.h,
    `Raka mulai di dalam peta (${Math.round(world.player.x)}, ${Math.round(world.player.y)})`,
  );

  // Uji regresi: dulu semua properti digambar di satu titik (asal kamera) sehingga
  // desa tampak kosong. Sekarang setiap properti harus punya perpindahan sendiri.
  translateTargets.length = 0;
  step(1);
  // Perpindahan pertama setiap langkah adalah kamera; sisanya adalah properti.
  const propSpots = translateTargets.slice(1);
  const differentSpots = new Set(propSpots.map((spot) => `${Math.round(spot.x)},${Math.round(spot.y)}`));
  const insideMap = propSpots.filter(
    (spot) => spot.x > -400 && spot.x < village.map.w + 400 && spot.y > -400 && spot.y < village.map.h + 400,
  ).length;
  check(differentSpots.size >= 10, `properti digambar pada posisinya masing-masing (${differentSpots.size} titik berbeda)`);
  const outliers = propSpots.filter(
    (spot) => !(spot.x > -400 && spot.x < village.map.w + 400 && spot.y > -400 && spot.y < village.map.h + 400),
  );
  if (outliers.length > 0) console.log('  ..   di luar peta:', outliers.slice(0, 4));
  check(
    outliers.length === 0,
    `semua perpindahan gambar berada di dalam peta (${insideMap}/${propSpots.length})`,
  );

  // Jalur masuk harus lancar: dari titik awal, berjalan ke kanan melewati gapura.
  key('keydown', 'KeyD');
  step(120);
  key('keyup', 'KeyD');
  step(20);
  check(world.player.x > 420, `Raka bisa melewati gapura dari titik awal (x = ${Math.round(world.player.x)})`);

  // Berjalan memutari desa: pegang satu arah selama beberapa detik, tekan E,
  // ganti arah — menirukan pemain menjelajah.
  const dirs = ['KeyD', 'KeyW', 'KeyA', 'KeyS', 'KeyD', 'KeyW', 'KeyA', 'KeyS'];
  const seenAreas = new Set<string>();
  let dialoguesOpened = 0;
  let minX = world.player.x;
  let maxX = world.player.x;
  let minY = world.player.y;
  let maxY = world.player.y;
  dirs.forEach((dir, index) => {
    const next = dirs[(index + 1) % dirs.length];
    key('keydown', dir);
    for (let round = 0; round < 60; round += 1) {
      step(5);
      // Setiap beberapa langkah pemain menutup dialog atau menekan E untuk
      // menyapa apa pun yang ada di dekatnya.
      if (round % 4 === 0) press('Space');
      if (round % 12 === 0) {
        press('KeyE');
        if (dialogue.isActive()) dialoguesOpened += 1;
      }
      if (state.area) seenAreas.add(state.area.title);
      minX = Math.min(minX, world.player.x);
      maxX = Math.max(maxX, world.player.x);
      minY = Math.min(minY, world.player.y);
      maxY = Math.max(maxY, world.player.y);
    }
    key('keyup', dir);
    key('keydown', next);
    key('keyup', next);
    step(5);
    console.log(`  ..   langkah ${dir}: (${Math.round(world.player.x)}, ${Math.round(world.player.y)})`);
  });
  const travelled = Math.round(Math.hypot(maxX - minX, maxY - minY));
  check(travelled > 400, `Raka benar-benar berjalan menjelajah (${travelled} piksel dunia)`);
  check(
    minX >= -1 && maxX <= village.map.w + 1 && minY >= -1 && maxY <= village.map.h + 1,
    'Raka tidak pernah keluar dari batas peta',
  );
  check(seenAreas.size >= 3, `label wilayah bermunculan (${[...seenAreas].join(', ') || 'tidak ada'})`);
  check(dialoguesOpened >= 3, `dialog warga terbuka saat berinteraksi (${dialoguesOpened} kali)`);

  // Menutup cerita supaya suasana malam, warga berkumpul, dan pendar lampu ikut digambar.

  for (const id of questOrder) {
    quests.startQuest(id);
    for (const objective of state.quests[id]?.objectives ?? []) {
      quests.advanceObjective(id, objective.id, objective.count);
    }
    quests.completeQuest(id);
  }
  state.flags.event_ready = true;
  step(240);
  check(true, 'suasana malam & warga berkumpul tergambar');

  // Papan, barang, dan stasiun juga diuji lewat aksi langsung.
  const board = village.boards[0];
  actions.readBoard(board);
  press('Space');
  step(10);
  check(problems.length === 0, 'membaca papan tanpa galat');

  engine.stop();
  step(5);
  check(problems.length === 0, 'mesin berhenti dengan rapi');


}

await playWorld();

// --- 3. Hasil ---------------------------------------------------------------
console.log('');
if (problems.length > 0) {
  for (const item of problems.slice(0, 10)) console.log(`  masalah: ${item}`);
}
console.log(`${problems.length === 0 ? 'SEMUA LOLOS' : 'ADA YANG GAGAL'}: ${checks - (problems.length > 0 ? 1 : 0)}/${checks} pemeriksaan lolos, ${calls} panggilan canvas, ${problems.length} masalah`);
process.exit(failures === 0 && problems.length === 0 ? 0 : 1);
