# TAPAK NUSA

> **Setiap langkah meninggalkan cerita.**

Game petualangan 2D tentang **gotong royong** dan **kearifan lokal Indonesia**.
Raka pulang ke Desa Arunika setelah lima tahun merantau, lalu ikut membantu warga
mempersiapkan acara **Guyub Desa** — mulai dari mencari bahan, belajar makna pola
kain, sampai menyiapkan lapangan tempat warga berkumpul.

* Tema lomba: **Kearifan Lokal untuk Indonesia Emas**
* Genre: **2D adventure · exploration · puzzle · story** (tanpa pertarungan)
* Durasi sekali main: **15–30 menit**
* Prinsip pengembangan: **small but memorable**

---

## Buka di VS Code (langkah pertama)

Repositori ini sudah menyiapkan berkas `.vscode/` (ekstensi yang disarankan,
tugas siap pakai, dan konfigurasi debug), jadi urutannya singkat:

1. **VS Code → File → Open Folder…** lalu pilih folder **akar** repositori ini
   (yang berisi `project.godot` dan `web/`).
2. Saat muncul tawaran *"This workspace has extension recommendations"* →
   **Install**. Yang penting:
   * **Godot Tools** (`geequlim.godot-tools`) — untuk menjalankan & men-debug
     proyek Godot dari VS Code.
   * **Python** + **Pylance** — untuk skrip di `tools/`.
   * Ekstensi **TypeScript/JavaScript bawaan VS Code** sudah cukup untuk `web/`.
   Bila perlu memasang manual: `Ctrl+Shift+X` → cari nama di atas.
3. Pilih mau mengerjakan yang mana:
   * **Versi web (paling cepat terlihat):** buka terminal (`Ctrl+`` ` ``) lalu
     jalankan tugas **`Web: pasang dependensi`** sekali (`Terminal → Run Task…`),
     kemudian **`Web: jalankan dev server`**, lalu buka http://localhost:5173.
     Atau cukup tekan **F5** dengan konfigurasi *Web: buka di Chrome*.
   * **Versi Godot:** pastikan Godot 4 sudah terpasang, lalu tekan **F5**
     dengan konfigurasi *Godot: jalankan proyek* (atau buka `project.godot`
     dengan Godot dan tekan F5 di sana).
4. Untuk memeriksa semuanya: **`Terminal → Run Task… → Semua: periksa proyek`**
   (menjalankan tiga pemeriksa Godot dan seluruh uji versi web).

Kalau `godot` tidak ada di PATH, buka **Settings → Godot Tools → Editor Path:
Godot 4** lalu arahkan ke berkas biner Godot 4 Anda.

Tugas lain yang tersedia di `Terminal → Run Task…`:

| Tugas | Kegunaan |
| --- | --- |
| `Web: jalankan dev server` | Vite dengan pratinjau langsung (port 5173) |
| `Web: periksa tipe` / `Web: uji semua` / `Web: build produksi` | Pemeriksaan & build versi web |
| `Godot: unduh dokumentasi API (sekali, butuh internet)` | Menyiapkan `tools/validate_project.py` |
| `Godot: periksa proyek` / `Godot: audit alur cerita` / `Godot: periksa peta` | Pemeriksa statis proyek Godot |
| `Godot: bangun ulang peta` | Menulis ulang `Village.tscn` + `data/world/village.json` |
| `Semua: periksa proyek` | Semua pemeriksaan di atas, berurutan |

## Dua Versi, Satu Cerita

Repositori ini memuat dua cara memainkan TAPAK NUSA dengan alur cerita yang sama:

| Versi | Lokasi | Teknologi | Cara menjalankan |
| --- | --- | --- | --- |
| **Godot (utama)** | akar repositori | Godot 4.x + GDScript | buka `project.godot`, tekan **F5** |
| **Web** | `web/` | React + TypeScript + Canvas 2D | `cd web && npm install && npm run dev` |

Keduanya membaca data yang sama di `data/` — naskah dialog, quest, barang, dan
catatan budaya tidak ditulis dua kali. Versi web menggambar seluruh isinya dari
bentuk dasar di Canvas (tanpa berkas gambar), sama seperti versi Godot yang
menggambar secara prosedural.

## Cara Menjalankan (Godot)

1. Pasang **Godot 4.x** (versi stabil apa pun; proyek memakai fitur dasar dan
   sudah diperiksa terhadap API Godot 4.2 sampai 4.7).
2. Buka Godot → **Import** → pilih `project.godot` di folder ini.
3. Tekan **F5** (Run Project). Scene utama: `res://scenes/main/Main.tscn`.

Tidak ada dependensi tambahan, tidak ada aset yang perlu diunduh: seluruh
gambar dan suara dibuat langsung di dalam game (prosedural).

## Kontrol

| Tombol | Fungsi |
| --- | --- |
| **W A S D** / panah | Berjalan |
| **E** | Berbicara / mengambil / membaca / menyusun |
| **SPACE** / **E** | Melanjutkan dialog |
| **Q** / **J** | Jurnal quest |
| **ESC** | Menu jeda (Lanjut, Quest, Inventaris, Catatan Budaya, Simpan, Pengaturan, Kembali ke Menu) |
| Klik kiri | Memilih dan meletakkan potongan puzzle |

## Tujuan Permainan

Menjalani enam tujuan cerita secara berurutan:

1. **Pulang** — menemui Mbah Seno.
2. **Persiapan Desa** — mengumpulkan bambu, tali ijuk, dan papan kayu.
3. **Yang Hilang** — mencari kain pola yang hilang.
4. **Belajar Bersama** — menyusun pola kain di bengkel Pak Jaya.
5. **Guyub** — menghias dan menyiapkan Lapangan Guyub.
6. **Tapak yang Ditinggalkan** — mengikuti acara dan menyaksikan penutup cerita.

Perjalanan pemain: **menjelajah → berbicara → menerima quest → mengumpulkan →
memecahkan puzzle → menemukan makna → membantu warga → maju**.

## Isi Permainan

* **Peta desa** yang hidup: gerbang desa, rumah Raka, alun-alun, balai desa,
  kebun kecil, sawah, bengkel, dan Lapangan Guyub — dengan tabrakan, kamera yang
  mengikuti pemain, dan batas peta.
* **5 NPC** dengan dialog berbeda sebelum dan sesudah quest: Mbah Seno, Sari,
  Pak Jaya, Bu Rini, dan Dimas; ditambah beberapa warga yang bisa diajak bicara.
* **Sistem dialog** dengan nama pembicara, potret prosedural, teks pendek, dan
  cabang cerita (dialog berubah mengikuti flag, quest, dan barang bawaan).
* **Sistem quest** (id, judul, deskripsi, tujuan, progres, selesai) dan
  **inventaris** sederhana untuk barang quest.
* **Dua puzzle**: menyusun pola kain di bengkel, dan menyiapkan perlengkapan di
  Lapangan Guyub. Salah susun tidak menghukum pemain — hanya diberi petunjuk.
* **Papan informasi** dan obrolan warga yang berisi catatan budaya
  (gotong royong, sambatan di sawah, ilmu yang diwariskan, sumur bersama,
  bahan alam, halaman warga) — pembelajaran disampaikan lewat dunia cerita,
  bukan menu "edukasi" terpisah.
* **Save system** JSON (`user://savegame.json`) untuk progres quest, barang,
  puzzle, dan posisi pemain. Pengaturan di `user://settings.cfg`.
* **Audio prosedural** (musik, suara lingkungan, langkah kaki, klik UI, berhasil,
  gagal, gong) dan **efek visual sederhana** (kilau interaksi, efek quest,
  efek puzzle, fade antar layar).
* **Ending sinematik** lalu layar kredit.

## Struktur Proyek

```
project.godot          Konfigurasi proyek, autoload, input, tema
autoload/              GameManager, QuestManager, DialogueManager, SaveManager
scenes/
  main/                Main (akar game), Opening (pembuka)
  player/              Player (Raka)
  npc/                 Npc, Villager
  world/               Village (Desa Arunika), AreaZone, SupplyStation
  props/               Prop (rumah, pohon, papan, lampu, …), ItemPickup, InfoBoard
  ui/                  MainMenu, Hud, DialogueBox, PauseMenu, panel-panel
  puzzle/              PatternPuzzle, PrepPuzzle
  ending/              Ending, Credits
scripts/
  player/ npc/ world/  Perilaku objek di dunia
  ui/                  Antarmuka
  puzzle/              Dua puzzle
  quest/ inventory/    Data quest & inventaris
  managers/            Sistem audio
  util/                Palette, DrawKit, TextureFactory, CharacterVisual, SparkleFx, ProceduralAudio
data/
  dialogue/            Naskah dialog (dengan kondisi cerita)
  quests/ items/ notes/ Data quest, barang, catatan budaya
assets/
  ui/theme/            Tema antarmuka (TapakNusa.tres)
  characters/ environment/ ui/ audio/ fonts/   Tempat aset tambahan (lihat catatan di dalam)
tools/                 Skrip bantu pengembangan (tidak diimpor Godot)
web/                   Versi web (React + TypeScript + Canvas 2D)
  src/core/            Data, quest, dialog, inventaris, simpan/muat, audio
  src/game/            Mesin dunia: gambar karakter, properti, tanah, partikel
  src/ui/              Layar & panel antarmuka
  tools/               Uji otomatis alur cerita, gambar, dan antarmuka
```

## Pengembangan & Pemeriksaan

Karena proyek ini dikembangkan tanpa membuka editor setiap saat, ada beberapa
skrip bantu di `tools/`:

* `python3 tools/validate_project.py` — memeriksa GDScript, scene `.tscn`,
  `project.godot`, dan data JSON: kelas/nama fungsi yang tidak ada di Godot,
  jumlah argumen pemanggilan fungsi dan `emit` sinyal, kecocokan fungsi yang
  disambung ke sinyal, deklarasi ganda, tipe node vs skrip, properti node yang
  salah, `res://` yang hilang, id dialog/quest/barang yang tidak cocok, serta
  kompatibilitas API Godot 4.2–4.7. Semua tanpa perlu membuka Godot.
* `python3 tools/audit_flow.py` — menelusuri alur cerita: setiap objective punya
  pemicu, setiap flag yang dibaca pernah di-set, semua id dialog/quest/barang/
  suara yang ditulis di skrip benar-benar ada, dan akhir cerita bisa dicapai.
* `python3 tools/check_map.py` — menyusun bidang rintangan dari `Village.tscn`
  lalu menelusuri peta: memastikan titik spawn tidak tertimbun, pemain tidak bisa
  keluar peta, dan semua barang, NPC, papan, serta titik kumpul warga terjangkau.
* `python3 tools/gen_village.py` — membangun ulang `scenes/world/Village.tscn`
  dari satu spesifikasi tata letak (memudahkan menggeser rumah, pohon, atau NPC).
* `python3 tools/make_icon.py` — membuat `icon.png` game.
* `python3 tools/fetch_api_docs.py` — mengunduh dokumentasi kelas Godot untuk
  pemeriksa statis (hanya untuk pengembangan, tidak dibutuhkan untuk bermain).

Contoh urutan pemeriksaan sebelum membuka Godot:

```bash
# sekali saja, butuh internet: unduh dokumentasi API Godot untuk pemeriksa
python3 tools/fetch_api_docs.py --dir /tmp/godot_api    --tag 4.7.2-stable
python3 tools/fetch_api_docs.py --dir /tmp/godot_api_42 --tag 4.2-stable

# lalu, tanpa internet:
python3 tools/validate_project.py    # 0 error, 0 peringatan
python3 tools/audit_flow.py          # 0 masalah keras
python3 tools/check_map.py           # semua titik penting terjangkau
```

Hasil terakhir: **45 skrip, 24 scene, 0 error, 0 peringatan**; alur cerita 0
masalah; peta 5,41 dari 6,4 juta px² terjangkau dengan 22 titik penting
(termasuk titik kumpul warga) semuanya bisa dicapai, dan pemain tidak bisa
keluar dari peta.

Untuk versi web:

```bash
cd web && npm test   # 135 pemeriksaan: 59 alur, 16 gambar, 60 antarmuka
```

Semua lolos: cerita bisa ditamatkan, seluruh 130 properti peta tergambar tanpa
galat, tidak ada koordinat NaN, dan antarmuka React tidak memunculkan satu pun
galat saat dijalankan dari menu sampai kredit.

## Versi Web (React)

Versi ini memakai **React + TypeScript + Vite** dengan **Canvas 2D** buatan
sendiri (tanpa mesin game pihak ketiga), dan menjalankan alur yang sama persis:
pembuka → enam quest → dua puzzle → acara → penutup → kredit.

```bash
cd web
npm install          # sekali saja
npm run dev          # http://localhost:5173
```

Kontrol sama seperti versi Godot: **WASD**/panah berjalan, **E** berbicara atau
mengambil, **SPACE/E/Enter** melanjutkan dialog, **Q/J** jurnal quest, **ESC**
menu jeda, klik kiri menyusun puzzle.

Pemeriksaan otomatis (tanpa peramban, memakai jsdom):

```bash
cd web
npm test             # typecheck + tiga uji di bawah
npm run test:flow    # alur cerita penuh: menu → enam quest → puzzle → kredit
npm run test:render  # semua properti & karakter digambar lewat Canvas tiruan
npm run test:ui      # memasang seluruh antarmuka React dan menjalankannya
```

`npm run build` menghasilkan berkas statis di `web/dist/` yang bisa dibuka
langsung dari server berkas biasa.

## Catatan Budaya


**Guyub Desa adalah tradisi fiktif** di dunia cerita TAPAK NUSA. Ia dibuat
sebagai gambaran semangat gotong royong masyarakat desa di Indonesia — bukan
nama ritual resmi dari daerah tertentu, dan tidak mewakili seluruh budaya
Jawa. Nilai yang ingin disampaikan bersifat umum: warga bekerja bersama karena
merasa saling membutuhkan, dan yang diwariskan bukan hanya benda, tetapi juga
ilmu serta alasan untuk menjaganya.

Semua gambar dan suara dibuat sendiri di dalam game. Tidak ada aset berhak
cipta yang diunduh atau disalin.

## Pengembang

**Game Development, Concept, Programming, Game Design, UI/UX, dan Story:**
**Fredsa Stanlye**

Dibuat dengan **Godot 4.x** dan **GDScript**. Versi 1.0.0.
