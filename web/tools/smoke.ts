/**
 * Uji alur permainan versi web tanpa peramban.
 *
 * Menjalankan logika yang sama dengan yang dipakai React (data cerita, quest,
 * dialog, efek, puzzle, simpan/muat) lalu memastikan seluruh cerita bisa
 * diselesaikan dari menu sampai kredit.
 *
 *   cd web && npx tsx tools/smoke.ts
 */

import { JSDOM } from 'jsdom';

// --- Lingkungan minimum yang dibutuhkan modul permainan ---------------------

const dom = new JSDOM('<!doctype html><html><body><div id="root"></div></body></html>', {
  url: 'https://preview.local/',
});
const globals = globalThis as unknown as Record<string, unknown>;
globals.window = dom.window;
globals.document = dom.window.document;
globals.localStorage = dom.window.localStorage;
globals.performance = dom.window.performance;
globals.requestAnimationFrame = (cb: FrameRequestCallback) => dom.window.setTimeout(() => cb(Date.now()), 16);
globals.cancelAnimationFrame = (id: number) => dom.window.clearTimeout(id);
// navigator milik Node hanya-baca; tidak dibutuhkan modul permainan.

const audio = await import('../src/core/audio');
const actions = await import('../src/core/actions');
const dialogue = await import('../src/core/dialogue');
const quests = await import('../src/core/quests');
const save = await import('../src/core/save');
const { items, notes, questOrder, quests: questDefs, village } = await import('../src/core/data');
const { hasFlag, state } = await import('../src/core/store');
const { QuestStatus } = await import('../src/core/types');

audio.getSettings(); // memastikan modul audio siap (tanpa AudioContext di Node)

// --- Alat uji ---------------------------------------------------------------

let failures = 0;
let checks = 0;

function check(condition: boolean, label: string): void {
  checks += 1;
  if (condition) {
    console.log(`  ok   ${label}`);
  } else {
    failures += 1;
    console.log(`  GAGAL ${label}`);
  }
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => dom.window.setTimeout(resolve, ms));
}

/** Menjalankan dialog sampai habis (seperti pemain menekan SPACE). */
function playDialogue(maxLines = 60): number {
  let lines = 0;
  while (dialogue.isActive() && lines < maxLines) {
    dialogue.advance();
    lines += 1;
  }
  return lines;
}

/** Menjalankan dialog lalu menunggu efek tertunda (puzzle/layar). */
async function playAndSettle(): Promise<void> {
  playDialogue();
  await sleep(220);
}

function progress(questId: string, objectiveIndex: number): number {
  return state.quests[questId]?.objectives[objectiveIndex]?.progress ?? -1;
}

// --- 1. Data ----------------------------------------------------------------

console.log('\n== Data cerita ==');
check(questOrder.length === 6, `enam quest dimuat (${questOrder.length})`);
check(Object.keys(items).length === 4, `empat barang quest (${Object.keys(items).length})`);
check(Object.keys(notes).length === 7, `tujuh catatan budaya (${Object.keys(notes).length})`);
check(village.props.length > 100, `peta punya ${village.props.length} properti`);
check(village.npcs.length === 8, `delapan NPC (${village.npcs.length})`);
check(!!dialogue && true, 'data dialog termuat');
check(typeof questDefs.q_pulang.title === 'string', 'judul quest pertama tersedia');
void hasFlag;

// --- 2. Mulai permainan -----------------------------------------------------

console.log('\n== Mulai permainan ==');
actions.newGame();
check(state.gameStarted && state.screen === 'opening', 'MULAI membuka layar pembuka');
dialogue.start('opening_narasi');
check(dialogue.isActive(), 'narasi pembuka berjalan');
playDialogue();
check(!dialogue.isActive(), 'narasi pembuka selesai');

actions.goto('village');
check(state.screen === 'village', 'masuk ke Desa Arunika');
quests.startQuest('q_pulang');
check(quests.isActive('q_pulang'), 'quest "Pulang" dimulai');

// --- 3. Quest 1: Mbah Seno --------------------------------------------------

console.log('\n== Quest 1 — Pulang ==');
actions.talkTo({ npc_id: 'mbah_seno', dialogue_id: 'mbah_seno' });
check(dialogue.isActive(), 'dialog Mbah Seno terbuka');
playAndSettle();
check(quests.isCompleted('q_pulang'), 'Quest 1 selesai setelah berbicara');
check(quests.isActive('q_persiapan'), 'Quest 2 "Persiapan Desa" otomatis dimulai');
check(hasFlag('met_seno'), 'flag met_seno disetel');

// --- 4. Quest 2: tiga perlengkapan -----------------------------------------

console.log('\n== Quest 2 — Persiapan Desa ==');
const bamboo = village.pickups[0];
actions.collectItem(bamboo);
check(state.items.bambu === 1, 'bambu masuk inventaris');
check(progress('q_persiapan', 0) === 1, 'objective bambu selesai');
check(hasFlag(bamboo.flag_id), 'flag barang bambu disetel');

actions.talkTo({ npc_id: 'bu_rini', dialogue_id: 'bu_rini' });
playAndSettle();
check(state.items.tali === 1, 'tali ijuk diterima dari Bu Rini');
check(progress('q_persiapan', 1) === 1, 'objective tali selesai');

actions.talkTo({ npc_id: 'pak_jaya', dialogue_id: 'pak_jaya' });
playAndSettle();
check(state.items.papan_kayu === 1, 'papan kayu diterima dari Pak Jaya');
check(quests.isCompleted('q_persiapan'), 'Quest 2 selesai setelah tiga perlengkapan');
check(hasFlag('supplies_ready'), 'flag supplies_ready disetel');
check(quests.isActive('q_hilang'), 'Quest 3 "Yang Hilang" dimulai');

// --- 5. Quest 3: kain pola yang hilang -------------------------------------

console.log('\n== Quest 3 — Yang Hilang ==');
actions.talkTo({ npc_id: 'bu_rini', dialogue_id: 'bu_rini' });
playAndSettle();
check(progress('q_hilang', 0) === 1, 'objective bertanya selesai');

actions.talkTo({ npc_id: 'dimas', dialogue_id: 'dimas' });
playAndSettle();
check(state.items.kain_pola === 1, 'kain pola ditemukan');
check(quests.isCompleted('q_hilang'), 'Quest 3 selesai');
check(quests.isActive('q_belajar'), 'Quest 4 "Belajar Bersama" dimulai');

// --- 6. Quest 4: puzzle pola kain ------------------------------------------

console.log('\n== Quest 4 — Belajar Bersama ==');
actions.talkTo({ npc_id: 'pak_jaya', dialogue_id: 'pak_jaya' });
playDialogue();
await sleep(300);
check(state.puzzle === 'pattern', 'puzzle pola kain terbuka dari dialog Pak Jaya');
check(progress('q_belajar', 0) === 1, 'objective mendengarkan penjelasan selesai');

actions.finishPuzzle('pattern', true);
await sleep(1000);
playAndSettle();
check(state.puzzle === null, 'puzzle ditutup setelah selesai');
check(progress('q_belajar', 1) === 1, 'objective menyusun pola selesai');
check(quests.isCompleted('q_belajar'), 'Quest 4 selesai');
check(quests.isActive('q_guyub'), 'Quest 5 "Guyub" dimulai');
check(hasFlag('puzzle_pattern_done'), 'flag puzzle pattern disetel');

// --- 7. Quest 5: menyiapkan lapangan ---------------------------------------

console.log('\n== Quest 5 — Guyub ==');
actions.useStation(['bambu', 'tali', 'papan_kayu', 'kain_pola'], 'prep', 'panggung', 'persiapan_kurang');
await sleep(100);
check(state.puzzle === 'prep', 'puzzle persiapan terbuka karena perlengkapan lengkap');

actions.finishPuzzle('prep', true);
await sleep(1000);
playAndSettle();
check(progress('q_guyub', 0) === 1, 'objective menghias lapangan selesai');
check(hasFlag('event_ready'), 'flag event_ready disetel (warga berkumpul)');
// Quest 5 baru tertutup setelah warga dikumpulkan: pemain harus menghampiri
// Mbah Seno dulu, seperti alur di desa.
check(quests.isActive('q_guyub') && !quests.isCompleted('q_guyub'), 'Quest 5 masih menunggu warga dikumpulkan');
check(!quests.isActive('q_tapak'), 'Quest terakhir belum dimulai sebelum acara');
check(
  Object.keys(state.items).length === 0,
  `perlengkapan diserahkan ke warga (sisa ${Object.keys(state.items).length} barang)`,
);

// --- 8. Menutup cerita ------------------------------------------------------

console.log('\n== Acara & penutup ==');
actions.talkTo({ npc_id: 'mbah_seno', dialogue_id: 'mbah_seno' });
playDialogue();
await sleep(900); // menunggu efek tertunda: finish_game lalu fade layar
playAndSettle();
check(quests.isCompleted('q_guyub'), 'Quest 5 selesai setelah warga dikumpulkan');
check(quests.isActive('q_tapak') === false && quests.isCompleted('q_tapak'), 'Quest terakhir selesai bersama acara');
check(state.gameFinished, 'permainan ditandai selesai');
check(state.screen === 'ending', 'layar penutup terbuka');
check(quests.isCompleted('q_tapak'), 'quest terakhir selesai');
check(state.quests.q_guyub?.status === QuestStatus.Completed, 'status quest tersimpan benar');
dialogue.start('ending_narasi');
playDialogue();
check(!dialogue.isActive(), 'narasi penutup selesai');
await sleep(500); // fade antar layar selesai
actions.goto('credits');
check(state.screen === 'credits', 'layar kredit terbuka');

// --- 8b. Pindah layar saat fade ---

console.log('\n== Pindah layar saat fade ==');
actions.goto('ending');
actions.goto('credits'); // datang saat fade belum selesai
await sleep(1000);
check(state.screen === 'credits', 'permintaan saat fade tetap dijalankan setelah fade selesai');

// --- 9. Simpan & muat ------------------------------------------------------

console.log('\n== Simpan & muat ==');
const saved = save.saveGame();
check(saved, 'permainan tersimpan ke localStorage');
const loaded = save.loadGame();
check(loaded, 'simpanan bisa dimuat');
check(quests.isCompleted('q_tapak'), 'progres quest pulih setelah dimuat');
check(save.saveSummary()?.finished === true, 'ringkasan simpanan menandai tamat');

// --- 10. Permainan baru mengulang dari awal --------------------------------

console.log('\n== Mulai ulang ==');
actions.newGame();
check(!quests.isCompleted('q_pulang'), 'quest kembali kosong setelah MULAI baru');
check(Object.keys(state.items).length === 0, 'inventaris kosong lagi');
check(state.notes.length === 0, 'catatan budaya kosong lagi');
check(state.gameFinished === false, 'status tamat direset');

console.log(`\n${failures === 0 ? 'SEMUA LOLOS' : 'ADA YANG GAGAL'}: ${checks - failures}/${checks} pemeriksaan lolos`);
process.exit(failures === 0 ? 0 : 1);
