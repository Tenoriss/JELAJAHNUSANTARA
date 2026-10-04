# Assets/environment

Seluruh isi desa digambar dengan kode:

* `scripts/world/Prop.gd` — rumah, balai desa, bengkel, saung, panggung, gapura,
  pohon, bambu, sumur, bangku, lampu, meja, peti, tumpukan kayu, gerobak, keranjang,
  tong, padi, orang-orangan sawah, bunga, rumput, batu, teratai, pagar, umbul-umbul,
  tungku api, bukit, dan papan nama.
* `scripts/world/VillageGround.gd` — tanah, jalan setapak, plaza, sawah, kolam,
  kebun, dan bunga di atas tanah.
* `scripts/util/TextureFactory.gd` — tekstur kecil yang dibuat saat game berjalan
  (titik lembut, cincin, daun, kilau, potret karakter).

Bila ingin memakai gambar asli, simpan PNG di folder ini lalu ganti pemanggilan
`DrawKit`/`Prop` dengan `Sprite2D` pada scene terkait.
