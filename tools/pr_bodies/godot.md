# TAPAK NUSA — versi Godot

> **Setiap langkah meninggalkan cerita.**
> Tema lomba: *Kearifan Lokal untuk Indonesia Emas* · 2D adventure · exploration · puzzle · story (tanpa pertarungan)

PR ini berisi **proyek Godot 4.x lengkap** di akar repositori: dari menu utama sampai kredit, siap dimainkan tanpa aset unduhan.

## Isi

- **45 skrip GDScript, 24 scene**: Main, Opening, Desa Arunika, Player, NPC/Villager, prop lingkungan, ItemPickup, InfoBoard, SupplyStation, dua puzzle, Ending, Credits, dan seluruh panel antarmuka.
- **Peta Desa Arunika** 3200x2000 px: 130 properti, 8 NPC (5 tokoh utama + 3 warga), 8 wilayah bernama, tabrakan, kamera mengikuti pemain dengan batas peta.
- **Enam quest berurutan**: Pulang → Persiapan Desa → Yang Hilang → Belajar Bersama → Guyub → Tapak yang Ditinggalkan.
- **Dua puzzle**: pola kain di bengkel Pak Jaya dan penyiapan Lapangan Guyub. Jawaban salah tidak menghukum — pemain diberi umpan balik.
- **Dialog bercabang**: kondisi flag/quest/barang menentukan kalimat; potret prosedural; teks pendek.
- **Inventaris barang quest**, **simpan/muat JSON** (`user://savegame.json`), **audio prosedural**, efek memudar, dan adegan penutup malam dengan warga berkumpul.

## Hasil pemeriksaan statis (tanpa membuka Godot)

| Pemeriksaan | Hasil |
| --- | --- |
| `python3 tools/validate_project.py` | **0 error, 0 peringatan** (45 skrip, 24 scene) |
| `python3 tools/audit_flow.py` | **0 masalah keras, 0 catatan** |
| `python3 tools/check_map.py` | 5,41 dari 6,4 juta px² terjangkau; **22/22 titik penting** tercapai |

Pemeriksa statis memeriksa kelas/fungsi Godot yang tidak ada, jumlah argumen pemanggilan, kecocokan sinyal, `res://` yang hilang, id dialog/quest/barang, dan kompatibilitas API Godot 4.2–4.7.

## Cara menjalankan

1. Pasang **Godot 4.x**.
2. Buka Godot → **Import** → pilih `project.godot` di folder ini.
3. Tekan **F5** (scene utama: `scenes/main/Main.tscn`).

Dari VS Code: buka folder akar, jawab *Install* pada tawaran ekstensi, lalu **F5** dengan konfigurasi *Godot: jalankan proyek*.

**Kontrol:** WASD/panah berjalan · E bicara/ambil/baca · SPACE/E melanjutkan dialog · Q/J jurnal quest · ESC menu jeda.

## Catatan

- Tidak ada aset berhak cipta: seluruh gambar dan suara dibuat di dalam game.
- **Guyub Desa adalah tradisi fiktif** dalam dunia cerita TAPAK NUSA — gambaran semangat gotong royong, bukan ritual resmi daerah tertentu dan tidak mewakili seluruh budaya Jawa.
- Kredit: Game Development, Concept, Programming, Game Design, UI/UX, dan Story — **Fredsa Stanlye**.

> PR berikutnya (*versi web* React) bertumpu pada PR ini, karena versi web memakai data cerita yang sama di `data/`.
