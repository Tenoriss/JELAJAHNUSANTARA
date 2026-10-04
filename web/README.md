# TAPAK NUSA — Versi Web

> **Setiap langkah meninggalkan cerita.**

Versi web dari game petualangan 2D **TAPAK NUSA**, dibuat dengan **React +
TypeScript + Vite** dan **Canvas 2D** buatan sendiri (tanpa mesin game pihak
ketiga). Alur cerita, naskah dialog, quest, dan barang dibaca dari folder `data/`
di akar repositori — sama persis dengan versi Godot, tidak ditulis dua kali.

* Tema lomba: **Kearifan Lokal untuk Indonesia Emas**
* Genre: **2D adventure · exploration · puzzle · story** (tanpa pertarungan)
* Durasi sekali main: **15–30 menit**
* Prinsip: **small but memorable** — satu peta kecil yang padat cerita

## Menjalankan

> **Dari VS Code:** buka folder **akar** repositori, jawab *Install* pada tawaran
> ekstensi, lalu **Terminal → Run Task… → `Web: pasang dependensi`** (sekali) dan
> **`Web: jalankan dev server`**. Bisa juga langsung tekan **F5** dengan
> konfigurasi *Web: buka di Chrome* — tugas dev server akan dijalankan otomatis.


Butuh **Node.js 18+** (diuji pada Node 22).

```bash
cd web
npm install     # sekali saja
npm run dev     # buka http://localhost:5173
```

Perintah lain:

```bash
npm run build      # periksa tipe lalu bungkus ke dist/ (berkas statis)
npm run preview    # mencoba hasil build
npm run typecheck  # hanya pemeriksaan tipe, tanpa menjalankan
```

Hasil `npm run build` berupa berkas statis di `web/dist/`; cukup ditaruh di
server berkas biasa (tidak butuh backend, basis data, atau server aplikasi).

## Kontrol

| Tombol | Fungsi |
| --- | --- |
| **W A S D** / panah | Berjalan |
| **E** | Berbicara / mengambil / membaca / menyusun |
| **SPACE** / **E** / **Enter** | Melanjutkan dialog |
| **Q** / **J** | Jurnal quest |
| **ESC** | Menu jeda (Lanjut, Quest, Inventaris, Catatan Budaya, Simpan, Pengaturan, kembali ke menu); menutup panel atau membatalkan puzzle |
| Klik kiri | Memilih potongan lalu meletakkannya di tempat tujuan |
| Klik pada dialog | Sama dengan SPACE |

## Alur Permainan

1. **Pulang** — menemui Mbah Seno di desa.
2. **Persiapan Desa** — mengumpulkan bambu, tali ijuk, dan papan kayu.
3. **Yang Hilang** — mencari kain pola yang hilang bersama Dimas.
4. **Belajar Bersama** — menyusun pola kain di bengkel Pak Jaya.
5. **Guyub** — menyiapkan Lapangan Guyub (mengumpulkan warga).
6. **Tapak yang Ditinggalkan** — mengikuti acara Guyub dan penutup cerita.

Puzzle salah tidak menghukum: pemain diberi umpan balik, dan setelah beberapa
percobaan tempat yang benar mulai ditandai. Simpanan memakai `localStorage`
(quest, inventaris, catatan budaya, posisi pemain, dan pengaturan volume) —
tanpa basis data maupun server.

## Struktur Berkas

```
web/
  index.html            Kerangka halaman
  src/
    main.tsx            Titik masuk React
    App.tsx             Pemilihan layar, tombol global, musik, efek memudar
    styles.css          Seluruh gaya antarmuka (tanpa pustaka CSS luar)
    core/               Logika permainan (tanpa React, bisa diuji sendiri)
      data.ts           Membaca data/ dari akar repositori
      store.ts          Keadaan permainan + langganan React
      quests.ts         Manajer quest: mulai, maju, selesai
      dialogue.ts       Pemilihan cabang dialog + efek tiap node
      actions.ts        Aksi pemain: mulai, pindah layar, ambil, puzzle, bicara
      save.ts           Simpan/muat localStorage
      audio.ts          Audio WebAudio: musik, suasana, efek (prosedural)
      villageTypes.ts   Tipe data peta hasil tools/gen_village.py
    game/               Gambar prosedural Canvas 2D
      engine.ts         Mesin dunia: gerak, tabrakan, kamera, NPC, partikel
      character.ts      Karakter & potret (Raka dan warga)
      props.ts          Rumah, balai, pohon, lampu, panggung, dll. (27 jenis)
      ground.ts         Jalan, sawah, kebun, kolam, alun-alun
      scenery.ts        Latar layar pembuka dan adegan penutup
      palette.ts        Warna bersama, mengikuti Palette.gd versi Godot
      draw.ts           Alat gambar dasar
    ui/                 Layar & panel React
      MainMenu, OpeningScreen, VillageScreen, Hud, DialogueBox,
      PauseMenu, panels, PuzzleOverlay, EndingScreen, CreditsScreen,
      Portrait, SettingsForm
  tools/                Uji otomatis (dijalankan dengan Node, tanpa peramban)
  vite.config.ts        Alias @data → ../data, host, port
```

## Uji Otomatis

Uji berjalan tanpa peramban: `jsdom` menyediakan DOM, sedangkan Canvas 2D
digantikan perekam yang mengawasi setiap panggilan gambar.

```bash
npm test             # typecheck + tiga uji di bawah
npm run test:flow    # 59 pemeriksaan alur cerita penuh sampai kredit
npm run test:render  # 16 pemeriksaan gambar + mesin dunia berjalan
npm run test:ui      # 60 pemeriksaan antarmuka React dari menu sampai kredit
```

Yang diperiksa:

* **Alur** — enam quest bisa ditamatkan, efek tiap dialog benar, puzzle mengubah
  progres, simpan/muat memulihkan keadaan, permainan baru mengulang dari awal.
* **Gambar** — seluruh 130 properti peta dan seluruh karakter digambar tanpa
  galat, tidak ada koordinat `NaN`/tak hingga, **setiap properti digambar pada
  posisinya sendiri di peta** (bukan menumpuk di satu titik), panggilan gambar
  per langkah dijaga di bawah batas supaya tetap ringan, Raka tidak bisa keluar
  peta dan bisa melewati gapura dari titik awal.
* **Antarmuka** — React dipasang sungguhan: menu, pengaturan, pembuka, HUD,
  dialog, panel jeda, kedua puzzle (termasuk umpan balik jawaban salah), adegan
  penutup, kredit, serta **LANJUTKAN** yang memulihkan simpanan. Syaratnya:
  tidak ada satu pun galat React.

## Catatan Teknis

* Tidak ada berkas gambar atau suara: karakter, properti, motif kain (SVG), dan
  efek suara dibuat di dalam game. Tidak ada aset berhak cipta yang diunduh.
* Peta di `data/world/village.json` dihasilkan oleh `python3 tools/gen_village.py`
  di akar repositori, sehingga tata letak versi Godot dan versi web selalu sama.
  Bila peta diubah, jalankan ulang skrip itu.
* Karakter digambar dengan titik asal di telapak kaki, lalu diurutkan atas-bawah
  berdasarkan `y` supaya Raka bisa berjalan di depan atau di belakang properti.
* Yang di luar layar tidak digambar (penyaringan kotak batas), sehingga hanya
  sekitar 4.000 panggilan Canvas per langkah walau peta berisi 130 properti.
* Properti digambar pada titik asal lokal lalu dipindahkan ke posisinya
  (`ctx.translate`), sama seperti `Node2D.position` versi Godot. Ada uji khusus
  yang memastikan hal ini benar-benar terjadi.
* Alat bantu pengembangan (perlu `@napi-rs/canvas`, tidak wajib):
  `npx tsx tools/shots.ts` membuat tangkapan layar latar & adegan,
  `npx tsx tools/engine-shot.ts` mengambil tangkapan dari **mesin dunia asli**
  (WorldEngine) untuk memeriksa desa tanpa membuka peramban.

## Bila Layar Terasa Gelap

Ada tiga hal yang bisa dicoba:

1. **Pengaturan → Kecerahan** (bisa dibuka dari menu utama maupun menu jeda).
   Nilai bawaannya 115%; naikkan sampai nyaman. Pengaturannya ikut tersimpan,
   dan hanya menerangkan gambar, bukan teks.
2. **Terangkan layar perangkat** — warna desa sengaja bernuansa tanah, dan
   adegan malam memang gelap.
3. Kalau yang tampak justru **layar kosong tanpa gambar sama sekali**, bukan
   gelap: sekarang ada panel galat yang menampilkan pesan aslinya. Salin pesan
   itu supaya bisa ditelusuri — tidak ada lagi layar gelap senyap.

## Pengembang

Game Development, Concept, Programming, Game Design, UI/UX, dan Story:
**Fredsa Stanlye**.

**Guyub Desa adalah tradisi fiktif** di dunia cerita TAPAK NUSA — gambaran
semangat gotong royong, bukan ritual resmi daerah tertentu dan tidak mewakili
seluruh budaya Jawa.
