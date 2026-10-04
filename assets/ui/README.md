# Assets/ui

Antarmuka TAPAK NUSA dibangun dari node Control Godot dan tema
`assets/ui/theme/TapakNusa.tres` (warna, sudut kotak, dan gaya tombol).

* `scenes/ui/` — MainMenu, Hud, DialogueBox, PauseMenu, QuestPanel,
  InventoryPanel, NotesPanel, SettingsPanel.
* `scripts/ui/UiKit.gd` — pembantu kecil untuk membuat label, tombol, dan panel
  dari kode supaya gaya visualnya konsisten.

Tidak ada berkas gambar UI. Ikon barang digambar oleh
`scripts/world/ItemIcon.gd` supaya sama dengan yang tampil di dunia.
