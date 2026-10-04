# TAPAK NUSA — versi web (React + Canvas 2D)

> **Setiap langkah meninggalkan cerita.**

PR ini menambahkan **versi web** dari TAPAK NUSA di folder `web/`: React 18 + TypeScript (strict) + Vite, dengan **Canvas 2D buatan sendiri** — tanpa mesin game pihak ketiga. Naskah dialog, quest, barang, dan catatan budaya dibaca dari `data/` yang sama seperti versi Godot, jadi ceritanya tidak ditulis dua kali.

Bertumpu pada PR *versi Godot* (cabang `pr/godot`), sehingga beda PR ini hanya berisi folder `web/` dan penyesuaian dokumentasi/pengaturan VS Code.

## Isi

- **Mesin dunia setara versi Godot** (`src/game/`): gerak & tabrakan, kamera mengikuti dengan batas peta, urutan gambar atas-bawah, NPC berjalan dan berkumpul, partikel, suasana malam, dan penyaringan gambar di luar layar — sekitar 4.000 panggilan Canvas per langkah untuk 130 properti.
- **Seluruh antarmuka** (`src/ui/`): menu utama, layar pembuka, HUD + pelacak quest, kotak dialog dengan potret prosedural, menu jeda beserta panel quest/inventaris/catatan budaya, **dua puzzle** (motif kain digambar sebagai SVG: kawung, ceplok, tumpal, parang), adegan penutup, dan kredit.
- **Simpan/muat** di `localStorage` dengan bentuk data yang sama seperti `user://savegame.json` versi Godot, lengkap dengan tombol **LANJUTKAN**; ditambah pengaturan volume dan **Kecerahan**.
- **Panel galat**: kegagalan skrip atau React menampilkan pesannya di layar, tidak lagi layar gelap tanpa penjelasan.

## Uji otomatis (tanpa peramban, memakai jsdom)

| Perintah | Hasil |
| --- | --- |
| `npm test` | **135/135 lolos** — 59 alur, 16 gambar, 60 antarmuka |
| `npm run build` | lolos; berkas statis di `web/dist/` (278 kB / 85 kB gzip) |

Ujinya benar-benar menjalankan permainannya: menamatkan enam quest sampai kredit, menggambar seluruh 130 properti dengan Canvas tiruan yang mengawasi setiap panggilan (termasuk memastikan **setiap properti digambar pada posisinya**), dan memasang antarmuka React sungguhan dari menu sampai kredit tanpa satu pun galat React.

## Bug yang ditemukan uji dan diperbaiki di PR ini

1. **Properti peta tidak tergambar** — seluruh 130 properti digambar di satu titik karena pemanggilnya tidak memindahkan gambar ke posisi properti; desa tampak kosong. Kini ada uji regresi yang mencatat setiap `ctx.translate`.
2. **Raka tersangkut di titik awal** — kotak tabrakannya bergeser 7 px dari `Player.tscn`.
3. **Macet di layar pembuka** — permintaan pindah layar saat fade berjalan dibuang, bukan ditunda.
4. **LANJUTKAN tidak pernah bisa dipakai** — pemuat simpanan tidak pernah tersambung.

## Cara menjalankan

```bash
cd web
npm install     # sekali saja (butuh Node.js 18+)
npm run dev     # http://localhost:5173
```

Dari VS Code: **Terminal → Run Task… → `Web: jalankan dev server`**, atau tekan **F5** dengan konfigurasi *Web: buka di Chrome* (dev server dinyalakan otomatis).

Alat bantu pengembangan (opsional, perlu `@napi-rs/canvas`): `npx tsx tools/shots.ts` dan `npx tsx tools/engine-shot.ts` membuat tangkapan layar dari mesin dunia asli untuk memeriksa tampilan tanpa membuka peramban.

## Catatan

- Tidak ada aset berhak cipta: tidak ada berkas gambar maupun audio; karakter, motif kain, dan efek suara dibuat di dalam game.
- **Guyub Desa adalah tradisi fiktif** — gambaran semangat gotong royong, bukan ritual resmi daerah tertentu dan tidak mewakili seluruh budaya Jawa.
- Kredit: Game Development, Concept, Programming, Game Design, UI/UX, dan Story — **Fredsa Stanlye**.
