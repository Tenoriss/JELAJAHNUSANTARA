# Assets/audio

Tidak ada berkas audio di proyek ini dan tidak ada aset berhak cipta yang
diunduh. Seluruh suara disintesis saat game berjalan oleh
`scripts/util/ProceduralAudio.gd`, lalu diputar lewat `scripts/managers/AudioSystem.gd`:

* Musik: `menu`, `village`, `ending`
* Suara lingkungan: `day`, `night`
* Efek: `click`, `hover`, `confirm`, `cancel`, `pickup`, `quest`, `note`,
  `place`, `success`, `fail`, `talk`, `sparkle`, `step1`, `step2`, `gong`

Bila ingin memakai berkas audio sendiri, letakkan di folder ini
(format `.ogg` disarankan) lalu ganti isi `ProceduralAudio` dengan
`load("res://assets/audio/...")` pada nama yang sama. Semua pemanggil
`GameManager.audio.play_sfx("...")` tidak perlu diubah.
