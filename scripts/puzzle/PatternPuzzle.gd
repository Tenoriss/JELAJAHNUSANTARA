class_name PatternPuzzle
extends PuzzleScreen
## Puzzle pola bengkel: menyusun kembali empat motif kain pada tempatnya.
##
## Pemain menyalin susunan yang tergambar pada contoh kain. Motif yang dipakai
## adalah nama motif yang dikenal pada kain tradisional Indonesia (kawung,
## ceplok, tumpal, parang), sesuai penjelasan Pak Jaya.

const MOTIF_IDS := ["kawung", "ceplok", "tumpal", "parang"]

const MOTIF_NAMES := {
	"kawung": "Kawung",
	"ceplok": "Ceplok",
	"tumpal": "Tumpal",
	"parang": "Parang",
}

const MOTIF_COLORS := {
	"kawung": Palette.INDIGO,
	"ceplok": Palette.BATIK_BROWN,
	"tumpal": Palette.ROSE,
	"parang": Palette.PLUM,
}


func puzzle_id() -> String:
	return "pattern"


func puzzle_title() -> String:
	return "Menyusun Pola Kain"


func puzzle_hint() -> String:
	return (
		"Pak Jaya: \"Susun potongan supaya sama dengan contoh kain di kanan atas. "
		+ "Kawung, ceplok, tumpal, parang — masing-masing punya tempatnya.\""
	)


func piece_ids() -> Array:
	return MOTIF_IDS.duplicate()


func piece_label(piece_id: String) -> String:
	return str(MOTIF_NAMES.get(piece_id, piece_id))


func slot_defs() -> Array:
	return [
		{"id": "p1", "pos": Vector2(0.3, 0.32), "correct": "kawung", "hint": "Pola kiri atas"},
		{"id": "p2", "pos": Vector2(0.7, 0.32), "correct": "ceplok", "hint": "Pola kanan atas"},
		{"id": "p3", "pos": Vector2(0.3, 0.72), "correct": "tumpal", "hint": "Pola kiri bawah"},
		{"id": "p4", "pos": Vector2(0.7, 0.72), "correct": "parang", "hint": "Pola kanan bawah"},
	]


# --- Gambar ---------------------------------------------------------------

func draw_stage() -> void:
	var stage := stage_rect()
	# kain yang sedang diperbaiki
	var cloth := Rect2(stage.position + Vector2(28.0, 26.0), stage.size - Vector2(56.0, 52.0))
	DrawKit.draw_box(self, cloth, Palette.with_alpha(Palette.INDIGO, 0.35), 14)
	DrawKit.draw_box_border(self, cloth, Color(0, 0, 0, 0), Palette.with_alpha(Palette.CREAM_DARK, 0.25), 1, 14)
	DrawKit.draw_text_centered(
		self, Vector2(cloth.get_center().x, cloth.position.y + 24.0), "Kain yang dipugar", 15, Palette.with_alpha(Palette.CREAM_DIM, 0.9)
	)


func draw_reference(rect: Rect2) -> void:
	DrawKit.draw_box_border(self, rect, Palette.with_alpha(Palette.INK_SOFT, 0.95), Palette.with_alpha(Palette.GOLD, 0.5), 2, 12)
	DrawKit.draw_text_centered(self, Vector2(rect.get_center().x, rect.position.y - 14.0), "Contoh kain", 15, Palette.GOLD_PALE)
	var half := rect.size * 0.5
	var cells := {
		"p1": Rect2(rect.position + Vector2(8.0, 8.0), half - Vector2(12.0, 12.0)),
		"p2": Rect2(rect.position + Vector2(half.x + 4.0, 8.0), half - Vector2(12.0, 12.0)),
		"p3": Rect2(rect.position + Vector2(8.0, half.y + 4.0), half - Vector2(12.0, 12.0)),
		"p4": Rect2(rect.position + Vector2(half.x + 4.0, half.y + 4.0), half - Vector2(12.0, 12.0)),
	}
	for slot in slot_defs():
		var cell: Rect2 = cells[slot["id"]]
		DrawKit.draw_box(self, cell, Palette.with_alpha(Palette.CREAM, 0.9), 6)
		_draw_motif(str(slot["correct"]), cell.grow(-6.0))


func draw_piece(piece_id: String, rect: Rect2) -> void:
	DrawKit.draw_box_border(
		self, rect, Palette.with_alpha(Palette.CREAM, 0.92), Palette.with_alpha(Palette.BATIK_BROWN, 0.8), 2, 10
	)
	_draw_motif(piece_id, rect.grow(-10.0))
	var label_y := rect.end.y - 6.0
	DrawKit.draw_text_centered(self, Vector2(rect.get_center().x, label_y), piece_label(piece_id), 13, Palette.INK)


func _draw_motif(piece_id: String, rect: Rect2) -> void:
	var color: Color = MOTIF_COLORS.get(piece_id, Palette.INDIGO)
	var center := rect.get_center()
	var radius := minf(rect.size.x, rect.size.y) * 0.5
	match piece_id:
		"kawung":
			# empat bulatan mengelilingi titik tengah
			var offset := radius * 0.42
			for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
				DrawKit.draw_ellipse(self, center + corner * offset, Vector2(radius * 0.3, radius * 0.4), color)
			DrawKit.draw_ellipse(self, center, Vector2(radius * 0.14, radius * 0.14), color)
		"ceplok":
			# roset bintang delapan arah
			for index in 8:
				var angle := TAU * float(index) / 8.0
				var point := center + Vector2(cos(angle), sin(angle)) * radius * 0.5
				DrawKit.draw_ellipse(self, point, Vector2(radius * 0.2, radius * 0.2), color)
			DrawKit.draw_ellipse(self, center, Vector2(radius * 0.26, radius * 0.26), color)
		"tumpal":
			# deretan segitiga
			var count := 5
			var step := rect.size.x / float(count)
			for index in count:
				var left := rect.position.x + step * float(index)
				var base_y := rect.end.y - radius * 0.35
				DrawKit.draw_poly(
					self,
					PackedVector2Array(
						[
							Vector2(left + 2.0, base_y),
							Vector2(left + step - 2.0, base_y),
							Vector2(left + step * 0.5, rect.position.y + radius * 0.35),
						]
					),
					color
				)
			DrawKit.draw_line_soft(
				self, Vector2(rect.position.x, base_y), Vector2(rect.end.x, base_y), color, 3.0
			)
		"parang":
			# garis miring berulang, dipotong pada batas kotak
			var step := radius * 0.42
			var width := rect.size.x
			var height := rect.size.y
			var offset := step
			while offset < width + height:
				var start := Vector2(
					rect.position.x + minf(offset, width), rect.end.y - maxf(offset - width, 0.0)
				)
				var end := Vector2(
					rect.position.x + maxf(offset - height, 0.0), rect.end.y - minf(offset, height)
				)
				DrawKit.draw_line_soft(self, start, end, color, 5.0)
				offset += step
		_:
			DrawKit.draw_ellipse(self, center, Vector2(radius, radius), color)
