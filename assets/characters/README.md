# Assets/characters

Folder ini sengaja dibiarkan berisi penjelasan saja.

Semua karakter TAPAK NUSA (Raka, Mbah Seno, Sari, Pak Jaya, Bu Rini, Dimas, dan
warga desa) digambar langsung dengan kode lewat `scripts/util/CharacterVisual.gd`
menggunakan palet warna di `scripts/util/Palette.gd`. Jadi game tetap berjalan
tanpa satu pun berkas gambar.

Kalau nanti ingin memakai sprite asli:

1. Simpan gambar PNG di folder ini (mis. `raka_idle.png`).
2. Buka `scenes/player/Player.tscn`, ganti node `Visual` menjadi `AnimatedSprite2D`
   atau tambahkan `Sprite2D` sebagai anak dari `Visual`.
3. Jangan lupa menyesuaikan posisi badan (`Body`) dan titik asal sprite supaya
   tetap berada di atas tanah.
