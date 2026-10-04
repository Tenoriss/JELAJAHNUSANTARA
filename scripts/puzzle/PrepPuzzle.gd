class_name PrepPuzzle
extends PuzzleScreen
## Puzzle persiapan: meletakkan perlengkapan pada tempat yang benar di
## Lapangan Guyub. Tidak ada hitungan rumit — hanya mencocokkan bahan dengan
## kegunaannya, seperti warga membagi pekerjaan saat gotong royong.

const PIECES := [
	{"id": "bambu", "label": "Bambu", "hint": "Berdiri tegak sebagai penopang gapura"},
	{"id": "tali", "label": "Tali Ijuk", "hint": "Mengikat supaya sambungan tidak lepas"},
	{"id": "papan_kayu", "label": "Papan Kayu", "hint": "Permukaan rata untuk meja panjang"},
	{"id": "kain_pola", "label": "Kain Pola", "hint": "Dipasang sebagai hiasan bercorak"},
]

var _icons: Dictionary = {}


func puzzle_id() -> String:
	return "prep"


func puzzle_title() -> String:
	return "Menyiapkan Lapangan"


func puzzle_hint() -> String:
	return "Sari: \"Letakkan setiap bahan di tempat yang sesuai. Pilih bahannya dulu, lalu klik tempatnya.\""


func piece_ids() -> Array:
	var ids: Array = []
	for piece in PIECES:
		ids.append(str(piece["id"]))
	return ids


func piece_label(piece_id: String) -> String:
	for piece in PIECES:
		if str(piece["id"]) == piece_id:
			return str(piece["label"])
	return piece_id


func slot_defs() -> Array:
	return [
		{"id": "s_tiang", "pos": Vector2(0.18, 0.34), "correct": "bambu", "hint": "Penopang gapura"},
		{"id": "s_ikat", "pos": Vector2(0.18, 0.72), "correct": "tali", "hint": "Ikatan sambungan"},
		{"id": "s_meja", "pos": Vector2(0.56, 0.7), "correct": "papan_kayu", "hint": "Meja panjang"},
		{"id": "s_hias", "pos": Vector2(0.84, 0.3), "correct": "kain_pola", "hint": "Hiasan panggung"},
	]


func _ready() -> void:
	super._ready()
	for piece in PIECES:
		var icon := ItemIcon.new()
		icon.setup(str(Inventory.entry(str(piece["id"])).get("icon", "bambu")), Inventory.item_color(str(piece["id"])))
		icon.z_index = 5
		add_child(icon)
		_icons[str(piece["id"])] = icon
	_layout_icons(true)


func _process(delta: float) -> void:
	_layout_icons(false, delta)


## Memindahkan ikon barang menuju tempatnya (baki atau slot).
func _layout_icons(snap: bool, delta := 0.0) -> void:
	for piece_id in _icons.keys():
		var icon: ItemIcon = _icons[piece_id]
		var target := _icon_target(str(piece_id))
		if snap:
			icon.position = target
		else:
			icon.position = icon.position.lerp(target, clampf(delta * 9.0, 0.0, 1.0))


func _icon_target(piece_id: String) -> Vector2:
	for slot in slot_defs():
		if str(placements.get(str(slot["id"]), "")) == piece_id:
			var rect := slot_rect(slot)
			return rect.get_center() + Vector2(0.0, rect.size.y * 0.34)
	var tray := tray_rect_for(piece_id)
	return tray.get_center() + Vector2(0.0, tray.size.y * 0.34)


func _on_placement_changed() -> void:
	_layout_icons(true)


# --- Gambar ---------------------------------------------------------------

func draw_stage() -> void:
	var stage := stage_rect()
	draw_rect(Rect2(stage.position.x, stage.end.y - 42.0, stage.size.x, 42.0), Palette.with_alpha(Palette.GRASS_DARK, 0.6))
	# gapura: dua tiang dan balok atas
	var left_x := stage.position.x + stage.size.x * 0.18
	var right_x := stage.position.x + stage.size.x * 0.84
	var top_y := stage.position.y + 36.0
	var bottom_y := stage.end.y - 42.0
	DrawKit.draw_pillar(self, Vector2(left_x, left_x * 0.0 + bottom_y), 18.0, bottom_y - top_y, Palette.WOOD, Palette.WOOD_DARK)
	DrawKit.draw_pillar(self, Vector2(right_x, bottom_y), 18.0, bottom_y - top_y, Palette.WOOD, Palette.WOOD_DARK)
	DrawKit.draw_box(self, Rect2(left_x - 12.0, top_y - 20.0, right_x - left_x + 24.0, 22.0), Palette.WOOD_LIGHT, 6)
	DrawKit.draw_box(self, Rect2(left_x - 20.0, top_y - 34.0, right_x - left_x + 40.0, 16.0), Palette.ROOF_TILE, 6)
	# meja panjang
	var table := Rect2(stage.position.x + stage.size.x * 0.44, bottom_y - 52.0, stage.size.x * 0.26, 12.0)
	DrawKit.draw_box(self, table, Palette.WOOD_LIGHT, 4)
	DrawKit.draw_pillar(self, Vector2(table.position.x + 14.0, bottom_y), 8.0, 52.0, Palette.WOOD_DARK, Palette.WOOD_DARK)
	DrawKit.draw_pillar(self, Vector2(table.end.x - 14.0, bottom_y), 8.0, 52.0, Palette.WOOD_DARK, Palette.WOOD_DARK)
	# panggung kecil untuk hiasan
	var deck := Rect2(stage.position.x + stage.size.x * 0.74, bottom_y - 26.0, stage.size.x * 0.2, 26.0)
	DrawKit.draw_box(self, deck, Palette.WOOD, 5)
	DrawKit.draw_text_centered(
		self, Vector2(stage.get_center().x, stage.position.y + 12.0), "Lapangan Guyub", 16, Palette.with_alpha(Palette.CREAM_DIM, 0.9)
	)


func draw_piece(piece_id: String, rect: Rect2) -> void:
	# Ikon barang digambar oleh node ItemIcon; di sini hanya labelnya.
	var label_y := rect.end.y + 18.0
	DrawKit.draw_text_centered(self, Vector2(rect.get_center().x, label_y), piece_label(piece_id), 13, Palette.CREAM_DIM)
