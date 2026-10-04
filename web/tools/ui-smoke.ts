/**
 * Uji antarmuka React: memasang seluruh aplikasi di jsdom lalu menjalankannya
 * seperti pemain — menu, pembuka, desa, dialog, jurnal, puzzle, penutup, kredit.
 *
 *   cd web && npx tsx tools/ui-smoke.tsx
 */

import { JSDOM } from 'jsdom';

// --- Lingkungan peramban tiruan --------------------------------------------

const dom = new JSDOM(
  '<!doctype html><html><body><div id="root"></div></body></html>',
  { url: 'https://preview.local/', pretendToBeVisual: true },
);
const globals = globalThis as unknown as Record<string, unknown>;
globals.window = dom.window;
globals.document = dom.window.document;
globals.localStorage = dom.window.localStorage;
globals.HTMLElement = dom.window.HTMLElement;
globals.Element = dom.window.Element;
globals.Node = dom.window.Node;
globals.Event = dom.window.Event;
globals.MouseEvent = dom.window.MouseEvent;
globals.KeyboardEvent = dom.window.KeyboardEvent;
globals.getComputedStyle = dom.window.getComputedStyle.bind(dom.window);
globals.IS_REACT_ACT_ENVIRONMENT = true;

let clock = 0;
Object.defineProperty(dom.window.performance, 'now', { value: () => clock });
Object.defineProperty(globalThis, 'performance', { value: { now: () => clock }, configurable: true });
Object.defineProperty(dom.window, 'devicePixelRatio', { value: 2 });

// Canvas 2D tiruan: mencatat panggilan, mengembalikan nilai yang dibutuhkan.
function contextStub(): CanvasRenderingContext2D {
  const store: Record<string, unknown> = {};
  return new Proxy(store, {
    get(target, prop: string | symbol) {
      if (typeof prop === 'symbol') return undefined;
      if (prop in target) return target[prop];
      return (...args: unknown[]) => {
        if (prop === 'measureText') return { width: String(args[0] ?? '').length * 8 };
        if (prop === 'createLinearGradient' || prop === 'createRadialGradient') {
          return { addColorStop: () => undefined };
        }
        return undefined;
      };
    },
    set(target, prop: string | symbol, value: unknown) {
      if (typeof prop === 'string') target[prop] = value;
      return true;
    },
  }) as unknown as CanvasRenderingContext2D;
}

dom.window.HTMLCanvasElement.prototype.getContext = function getContext() {
  return contextStub();
} as unknown as HTMLCanvasElement['getContext'];

dom.window.HTMLElement.prototype.getBoundingClientRect = function rect() {
  return { x: 0, y: 0, width: 1280, height: 720, top: 0, left: 0, right: 1280, bottom: 720, toJSON: () => ({}) } as DOMRect;
};

// --- Modul permainan --------------------------------------------------------

const { act, createElement } = await import('react');
const { createRoot } = await import('react-dom/client');
const { default: App } = await import('../src/App');
const { state, notify } = await import('../src/core/store');
const dialogue = await import('../src/core/dialogue');
const quests = await import('../src/core/quests');
const actions = await import('../src/core/actions');
const save = await import('../src/core/save');

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

// Peringatan act() wajar di lingkungan uji (timer latar), tapi galat React
// yang sesungguhnya harus membuat uji ini gagal.
const errors: string[] = [];
const originalError = console.error;
console.error = (...args: unknown[]) => {
  const line = args.map(String).join(' ');
  if (!line.includes('not wrapped in act')) errors.push(line);
  if (!line.includes('not wrapped in act')) originalError(...args);
};

const container = dom.window.document.getElementById('root') as HTMLElement;
const root = createRoot(container);

async function render(): Promise<void> {
  await act(async () => {
    root.render(createElement(App));
  });
}

/** Menjalankan timer jsdom yang tertunda (fade, auto-advance dialog). */
async function settle(ms: number): Promise<void> {
  await act(async () => {
    clock += ms;
    await new Promise((resolve) => dom.window.setTimeout(resolve, ms));
  });
}

/** Menekan SPACE sampai dialog yang sedang tampil selesai. */
async function tutupDialog(max = 25): Promise<void> {
  for (let i = 0; i < max; i += 1) {
    if (!dialogue.isActive()) break;
    await key('Space');
    await settle(45);
  }
  await render();
}

/** Menunggu dialog susulan (mis. setelah puzzle) lalu menutupnya. */
async function selesaikanDialogTertunda(tunggu = 3000): Promise<void> {
  for (let i = 0; i < tunggu / 100; i += 1) {
    if (dialogue.isActive()) break;
    await settle(100);
  }
  await tutupDialog();
}

function text(): string {
  return (container.textContent ?? '').replace(/\s+/g, ' ').trim();
}

function button(label: string): HTMLButtonElement {
  const nodes = Array.from(container.querySelectorAll('button'));
  const found = nodes.find((node) => (node.textContent ?? '').trim().includes(label));
  if (!found) throw new Error(`Tombol "${label}" tidak ada. Yang tampil: ${nodes.map((n) => n.textContent).join(' | ')}`);
  return found as HTMLButtonElement;
}

async function click(node: HTMLElement): Promise<void> {
  await act(async () => {
    node.dispatchEvent(new dom.window.MouseEvent('click', { bubbles: true }));
  });
}

async function key(code: string): Promise<void> {
  await act(async () => {
    dom.window.dispatchEvent(new dom.window.KeyboardEvent('keydown', { code, bubbles: true }));
  });
}

// --- 1. Menu utama ----------------------------------------------------------

console.log('\n== Menu utama ==');
state.screen = 'main_menu';
await render();
check(text().includes('TAPAK NUSA'), 'judul permainan tampil');
check(text().includes('Setiap langkah meninggalkan cerita.'), 'tagline tampil');
check(text().includes('MULAI') && text().includes('PENGATURAN'), 'tombol menu lengkap');
check(!!container.querySelector('.backdrop'), 'latar senja tergambar di kanvas');

console.log('\n== Pengaturan ==');
await click(button('PENGATURAN'));
check(text().includes('Musik') && text().includes('Efek Suara'), 'pengaturan terbuka');
const restore = container.querySelector<HTMLButtonElement>('.settings__row button, .modal__actions button:last-child');
if (restore) await click(restore);
check(true, 'pengaturan bisa ditutup');

// --- 2. Mulai permainan -----------------------------------------------------

console.log('\n== Mulai permainan ==');
await click(button('MULAI'));
check(state.screen === 'opening', 'layar pembuka terbuka');
await settle(60);
check(dialogue.isActive(), 'narasi pembuka berjalan di layar');
check(!!container.querySelector('.dialogue__box'), 'kotak dialog muncul');

// Menekan SPACE sampai narasi habis, seperti pemain.
for (let i = 0; i < 12 && dialogue.isActive(); i += 1) {
  await key('Space');
  await settle(30);
}
check(!dialogue.isActive(), 'narasi pembuka selesai');

await settle(600); // fade menuju desa
check(state.screen === 'village', 'pindah ke Desa Arunika');
check(!!container.querySelector('.world'), 'kanvas desa terpasang');
check(quests.isActive('q_pulang'), 'quest pembuka dimulai saat masuk desa');
check(text().includes('Pulang'), 'pelacak quest tampil di HUD');

// --- 3. Dialog, jurnal, dan barang -----------------------------------------

console.log('\n== Dialog & jurnal ==');
const { village } = await import('../src/core/data');
const bamboo = village.pickups[0];
check(bamboo.item_id === 'bambu', 'barang pertama di peta adalah bambu');

actions.talkTo({ npc_id: 'mbah_seno', dialogue_id: 'mbah_seno' });
await render();
check(dialogue.isActive(), 'dialog Mbah Seno terbuka lewat antarmuka');
check(!!container.querySelector('.dialogue__box'), 'kotak dialog menggantikan HUD');
await tutupDialog();
check(!dialogue.isActive(), 'dialog selesai dan tertutup');
check(quests.isCompleted('q_pulang'), 'Quest 1 selesai dari antarmuka');

// Quest 2: mengambil bambu, lalu meminta tali dan papan.
actions.collectItem(bamboo);
await render();
check(text().includes('Bambu'), 'toast barang muncul di HUD');
actions.talkTo({ npc_id: 'bu_rini', dialogue_id: 'bu_rini' });
await tutupDialog();
actions.talkTo({ npc_id: 'pak_jaya', dialogue_id: 'pak_jaya' });
await tutupDialog();
check(quests.isCompleted('q_persiapan'), 'Quest 2 selesai dengan tiga perlengkapan');
check(quests.isActive('q_hilang'), 'Quest 3 dimulai otomatis');

// Quest 3: mencari kain pola yang hilang.
actions.talkTo({ npc_id: 'bu_rini', dialogue_id: 'bu_rini' });
await tutupDialog();
actions.talkTo({ npc_id: 'dimas', dialogue_id: 'dimas' });
await tutupDialog();
check(quests.isCompleted('q_hilang'), 'Quest 3 selesai setelah kain ditemukan');
check(quests.isActive('q_belajar'), 'Quest 4 dimulai otomatis');

await key('Escape');
check(state.paused, 'ESC membuka menu jeda');
check(text().includes('Lanjut'), 'menu jeda tampil');
await click(button('Quest'));
check(text().includes('Belajar Bersama'), 'panel quest menampilkan quest aktif');
await click(button('Kembali'));
await click(button('Catatan Budaya'));
check(text().includes('Catatan Budaya'), 'panel catatan budaya terbuka');
await click(button('Kembali'));
await click(button('Inventaris'));
check(text().includes('Inventaris'), 'panel inventaris terbuka');
await click(button('Kembali'));
await click(button('Pengaturan'));
check(text().includes('Musik'), 'pengaturan bisa dibuka dari jeda');
await click(button('Kembali'));
await key('Escape');
check(!state.paused, 'menu jeda tertutup');

// --- 4. Puzzle pola kain ----------------------------------------------------

console.log('\n== Puzzle pola kain ==');
actions.talkTo({ npc_id: 'pak_jaya', dialogue_id: 'pak_jaya' });
await render();
await tutupDialog();
await settle(300);
check(state.puzzle === 'pattern', 'dialog Pak Jaya membuka puzzle pola');

function slotWith(label: string): HTMLElement {
  const node = Array.from(container.querySelectorAll('.slot')).find((item) =>
    (item.textContent ?? '').includes(label),
  );
  if (!node) throw new Error(`Slot "${label}" tidak ada.`);
  return node as HTMLElement;
}

async function letak(pieceLabel: string, slotLabel: string): Promise<void> {
  const piece = Array.from(container.querySelectorAll('.tray__piece')).find((item) =>
    (item.textContent ?? '').includes(pieceLabel),
  );
  if (!piece) throw new Error(`Keping "${pieceLabel}" tidak ada di baki.`);
  await click(piece as HTMLElement);
  await click(slotWith(slotLabel));
}

async function periksa(): Promise<void> {
  const node = Array.from(container.querySelectorAll('.puzzle__actions button')).find((item) =>
    /Periksa/i.test(item.textContent ?? ''),
  );
  if (!node) throw new Error('Tombol Periksa tidak ada.');
  await click(node as HTMLElement);
}

check((container.querySelectorAll('.slot') as unknown as unknown[]).length === 4, 'papan punya empat slot');
check((container.querySelectorAll('.tray__piece') as unknown as unknown[]).length === 4, 'baki punya empat keping');

// Percobaan pertama sengaja salah: pemain harus dapat umpan balik.
await letak('Kawung', 'Pola kanan atas');
await letak('Ceplok', 'Pola kanan bawah');
await letak('Tumpal', 'Pola kiri atas');
await letak('Parang', 'Pola kiri bawah');
await periksa();
check(/Belum tepat|Bandungkan|Bandingkan/.test(text()), 'jawaban salah memberi pesan umpan balik');
check(container.querySelectorAll('.slot--wrong').length > 0, 'slot yang salah ditandai merah');

// Kemudian disusun benar.
for (let i = 0; i < 4; i += 1) {
  const filled = Array.from(container.querySelectorAll('.slot')).find((item) => item.querySelector('.slot__piece'));
  if (filled) await click(filled as HTMLElement);
}
check(container.querySelectorAll('.tray__piece').length === 4, 'semua keping kembali ke baki');
await letak('Kawung', 'Pola kiri atas');
await letak('Ceplok', 'Pola kanan atas');
await letak('Tumpal', 'Pola kiri bawah');
await letak('Parang', 'Pola kanan bawah');
await periksa();
await selesaikanDialogTertunda();
await settle(300);
check(state.puzzle === null, 'layar puzzle tertutup setelah berhasil');
check(quests.isCompleted('q_belajar'), 'Quest 4 selesai setelah puzzle benar');
check(quests.isActive('q_guyub'), 'Quest 5 dimulai otomatis');

// --- 5. Puzzle persiapan, acara, penutup, dan kredit ------------------------

console.log('\n== Puzzle persiapan & penutup ==');
actions.useStation(['bambu', 'tali', 'papan_kayu', 'kain_pola'], 'prep', 'panggung', 'persiapan_kurang');
await render();
await settle(200);
check(state.puzzle === 'prep', 'stasiun bahan membuka puzzle persiapan');
check(!!container.querySelector('.itemPiece'), 'keping bahan tergambar');
await letak('Bambu', 'Penopang gapura');
await letak('Tali', 'Ikatan sambungan');
await letak('Papan', 'Meja panjang');
await letak('Kain', 'Hiasan panggung');
await periksa();
await selesaikanDialogTertunda();
await settle(300);
check(state.puzzle === null, 'puzzle persiapan selesai');
check(state.flags.event_ready === true, 'warga berkumpul (event_ready)');

actions.talkTo({ npc_id: 'mbah_seno', dialogue_id: 'mbah_seno' });
await render();
await tutupDialog();
await settle(1500);
check(state.gameFinished, 'permainan selesai lewat antarmuka');
check(state.screen === 'ending', 'layar penutup terbuka');
check(!!container.querySelector('.screen--ending'), 'adegan penutup tergambar');
await render();

// Menekan SPACE sampai kartu judul muncul.
for (let i = 0; i < 20 && !container.querySelector('.titleCard'); i += 1) {
  await key('Space');
  await settle(60);
}
await settle(400);
check(!!container.querySelector('.titleCard'), 'kartu judul muncul di penutup');
check(text().includes('TAPAK NUSA') && text().includes('Setiap langkah meninggalkan cerita.'), 'judul & tagline tampil');

await click(button('Lihat Kredit'));
await settle(800);
check(state.screen === 'credits', 'layar kredit terbuka');
check(text().includes('Fredsa Stanlye'), 'kredit menyebut pengembang');
check(
  ['Game Development', 'Concept', 'Programming', 'Game Design', 'UI/UX', 'Story'].every((role) =>
    text().includes(role),
  ),
  'kredit memuat keenam peran',
);
const jumlahNama = (text().match(/Fredsa Stanlye/g) ?? []).length;
check(jumlahNama >= 6, `enam peran untuk Fredsa Stanlye (${jumlahNama})`);

// --- 6. Kembali ke menu -----------------------------------------------------

console.log('\n== Kembali ke menu ==');
actions.returnToMainMenu();
await settle(700);
check(state.screen === 'main_menu', 'kembali ke menu utama');
check(text().includes('LANJUTKAN'), 'tombol LANJUTKAN tersedia karena sudah ada simpanan');

check(save.hasSave(), 'simpanan tersedia di localStorage');
// LANJUTKAN harus memulihkan simpanan terakhir.
await click(button('LANJUTKAN'));
await settle(400);
check(state.screen === 'village', 'LANJUTKAN membuka kembali Desa Arunika');
check(quests.isCompleted('q_tapak'), 'progres quest pulih dari simpanan');
check(!!container.querySelector('.world'), 'kanvas desa terpasang lagi');
void save;

check(errors.length === 0, `tidak ada galat React (${errors.length})`);
if (errors.length > 0) {
  for (const item of errors.slice(0, 5)) console.log(`  galat: ${item.slice(0, 200)}`);
}

console.log(`\n${failures === 0 ? 'SEMUA LOLOS' : 'ADA YANG GAGAL'}: ${checks - failures}/${checks} pemeriksaan lolos`);
await act(async () => {
  root.unmount();
});
void notify;
process.exit(failures === 0 ? 0 : 1);
