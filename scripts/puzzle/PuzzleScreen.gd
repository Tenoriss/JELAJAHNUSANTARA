class_name PuzzleScreen
extends Control
## Dasar kedua puzzle TAPAK NUSA (pola bengkel & persiapan lapangan).
##
## Cara mainnya sama di keduanya: pilih satu potongan di baki bawah, lalu klik
## tempat yang diinginkan. Klik potongan yang sudah terpasang untuk
## mengembalikannya. Menekan "Periksa" menilai susunan; jawaban salah diberi
## umpan balik, bukan hukuman. Kelas turunan hanya mengurus gambar dan data.

const SLOT_SIZE := Vector2(132.0, 132.0)
const PIECE_SIZE := Vector2(96.0, 96.0)
const TRAY_HEIGHT := 144.0

@onready var title_label: Label = $Title
@onready var hint_label: Label = $Hint
@onready var message_label: Label = $Message
@onready var submit_button: Button = $SubmitButton
@onready var cancel_button: Button = $CancelButton

var selected_id := ""
var placements: Dictionary = {}
var wrong_slots: Array[String] = []
var message := ""
var message_color: Color = Palette.CREAM
var attempts := 0
## Setelah "Periksa" ditekan, tempat yang sudah benar ditandai hijau.
var checked := false

var _busy := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	title_label.text = puzzle_title()
	hint_label.text = puzzle_hint()
	submit_button.pressed.connect(_on_submit_pressed)
	cancel_button.pressed.connect(cancel)
	_set_message("Pilih potongan di baki, lalu klik tempat yang diinginkan.", Palette.CREAM_DIM)
	submit_button.grab_focus()


# --- Bagian yang diisi kelas turunan --------------------------------------

func puzzle_id() -> String:
	return ""


func puzzle_title() -> String:
	return "Puzzle"


func puzzle_hint() -> String:
	return ""


## Daftar tempat: [{id, pos: Vector2 (0..1 dari panggung), correct: piece_id}]
func slot_defs() -> Array:
	return []


## Daftar potongan yang tersedia.
func piece_ids() -> Array:
	return []


func piece_label(piece_id: String) -> String:
	return piece_id


## Gambar potongan pada kotak tertentu.
func draw_piece(piece_id: String, rect: Rect2) -> void:
	pass


## Gambar hiasan panggung (opsional).
func draw_stage() -> void:
	pass


## Gambar contoh susunan yang benar (opsional).
func draw_reference(rect: Rect2) -> void:
	pass


# --- Tata letak ------------------------------------------------------------

func stage_rect() -> Rect2:
	return Rect2(90.0, 152.0, size.x - 180.0, size.y - 460.0)


func tray_rect() -> Rect2:
	return Rect2(90.0, size.y - 264.0, size.x - 180.0, TRAY_HEIGHT)


func slot_rect(slot: Dictionary) -> Rect2:
	var area := stage_rect().grow(-36.0)
	var pos: Vector2 = slot.get("pos", Vector2(0.5, 0.5))
	var center := area.position + Vector2(area.size.x * pos.x, area.size.y * pos.y)
	return Rect2(center - SLOT_SIZE * 0.5, SLOT_SIZE)


func reference_rect() -> Rect2:
	var stage := stage_rect()
	return Rect2(stage.end.x - 152.0, stage.position.y + 14.0, 132.0, 120.0)


func _unplaced_ids() -> Array:
	var out: Array = []
	for piece_id in piece_ids():
		if not placements.values().has(piece_id):
			out.append(piece_id)
	return out


func tray_rect_for(piece_id: String) -> Rect2:
	var unplaced := _unplaced_ids()
	var index := unplaced.find(piece_id)
	var area := tray_rect()
	if index < 0:
		return Rect2(area.position, PIECE_SIZE)
	var spacing := 148.0
	var total := spacing * float(unplaced.size())
	var start_x := area.get_center().x - total * 0.5 + spacing * 0.5
	var center := Vector2(start_x + spacing * float(index), area.get_center().y)
	return Rect2(center - PIECE_SIZE * 0.5, PIECE_SIZE)


# --- Masukan ---------------------------------------------------------------

func _gui_input(event: InputEvent) -> void:
	if _busy:
		return
	if not (event is InputEventMouseButton):
		return
	var mouse := event as InputEventMouseButton
	if not mouse.pressed or mouse.button_index != MOUSE_BUTTON_LEFT:
		return
	_on_click(mouse.position)
	accept_event()


func _on_click(point: Vector2) -> void:
	for slot in slot_defs():
		if slot_rect(slot).has_point(point):
			_on_slot_clicked(str(slot["id"]))
			return
	for piece_id in _unplaced_ids():
		if tray_rect_for(piece_id).has_point(point):
			_on_piece_clicked(str(piece_id))
			return
	_set_message("Klik salah satu tempat atau potongan.", Palette.CREAM_DIM)


func _on_slot_clicked(slot_id: String) -> void:
	if placements.has(slot_id):
		placements.erase(slot_id)
		wrong_slots.erase(slot_id)
		checked = false
		selected_id = ""
		GameManager.audio.play_sfx("click", -10.0)
		_set_message("Potongan dikembalikan ke baki.", Palette.CREAM_DIM)
		queue_redraw()
		return
	if selected_id.is_empty():
		_set_message("Pilih dulu satu potongan di baki bawah.", Palette.CREAM_DIM)
		return
	placements[slot_id] = selected_id
	selected_id = ""
	wrong_slots.erase(slot_id)
	checked = false
	GameManager.audio.play_sfx("place", -6.0)
	_set_message("Potongan terpasang. Periksa bila sudah lengkap.", Palette.CREAM)
	queue_redraw()
	_on_placement_changed()


func _on_piece_clicked(piece_id: String) -> void:
	selected_id = "" if selected_id == piece_id else piece_id
	GameManager.audio.play_sfx("click", -12.0)
	if selected_id.is_empty():
		_set_message("Pilihan dibatalkan.", Palette.CREAM_DIM)
	else:
		_set_message("Sekarang klik tempat untuk " + piece_label(piece_id) + ".", Palette.GOLD_PALE)
	queue_redraw()


## Dipanggil setiap kali susunan berubah (dipakai prep puzzle untuk ikon).
func _on_placement_changed() -> void:
	pass


func _on_submit_pressed() -> void:
	if _busy:
		return
	var slots := slot_defs()
	if placements.size() < slots.size():
		_set_message("Masih ada tempat yang belum terisi.", Palette.DANGER)
		GameManager.audio.play_sfx("fail", -6.0)
		queue_redraw()
		return
	checked = true
	wrong_slots.clear()
	for slot in slots:
		var slot_id := str(slot["id"])
		if str(placements.get(slot_id, "")) != str(slot["correct"]):
			wrong_slots.append(slot_id)
	if wrong_slots.is_empty():
		_succeed()
	else:
		attempts += 1
		GameManager.audio.play_sfx("fail")
		_set_message(_fail_message(), Palette.DANGER)
		queue_redraw()
		_shake()


func _fail_message() -> String:
	match mini(attempts, 3):
		1:
			return "Belum tepat. Bandingkan lagi bentuk tiap potongan."
		2:
			return "Masih ada yang salah. Tempat yang benar akan menyala hijau."
		_:
			return "Tidak apa-apa, ulangi perlahan. Setiap bentuk punya tempatnya."


func _succeed() -> void:
	_busy = true
	GameManager.audio.play_sfx("success")
	var center := stage_rect().get_center()
	SparkleFx.burst(self, center, Palette.GOLD, 24, 110.0)
	SparkleFx.ring_pop(self, center, Palette.GOLD_PALE, 190.0)
	_set_message("Susunan tepat!", Palette.HINT)
	submit_button.disabled = true
	cancel_button.disabled = true
	queue_redraw()
	await get_tree().create_timer(1.0).timeout
	GameManager.finish_puzzle(puzzle_id(), true)


func cancel() -> void:
	if _busy:
		return
	GameManager.audio.play_ui_click()
	GameManager.finish_puzzle(puzzle_id(), false)


func _shake() -> void:
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	for offset in [Vector2(9, 0), Vector2(-7, 0), Vector2(5, 0), Vector2(-3, 0), Vector2.ZERO]:
		tween.tween_property(self, "position", offset, 0.045)


func _set_message(text: String, color: Color) -> void:
	message = text
	message_color = color
	message_label.text = text
	message_label.add_theme_color_override("font_color", color)


# --- Menggambar ------------------------------------------------------------

func _draw() -> void:
	_draw_backdrop()
	draw_stage()
	draw_reference(reference_rect())
	_draw_slots()
	_draw_tray()


func _draw_backdrop() -> void:
	var rect := get_rect()
	draw_rect(rect, Palette.with_alpha(Palette.INK, 0.9))
	var stage := stage_rect()
	DrawKit.draw_box_border(self, stage, Palette.with_alpha(Palette.INK_SOFT, 0.95), Palette.with_alpha(Palette.GOLD, 0.35), 2, 16)
	# ornamen sudut panggung
	for corner in [stage.position, Vector2(stage.end.x, stage.position.y), Vector2(stage.position.x, stage.end.y), stage.end]:
		DrawKit.draw_ellipse(self, corner, Vector2(6, 6), Palette.with_alpha(Palette.GOLD, 0.5))


func _draw_slots() -> void:
	for slot in slot_defs():
		var slot_id := str(slot["id"])
		var rect := slot_rect(slot)
		var placed: String = str(placements.get(slot_id, ""))
		var wrong := wrong_slots.has(slot_id)
		var border := Palette.with_alpha(Palette.GOLD, 0.55)
		if wrong:
			border = Palette.DANGER
		elif checked:
			border = Palette.HINT
		var fill := Palette.with_alpha(Palette.INK, 0.75)
		if not placed.is_empty():
			fill = Palette.with_alpha(Palette.INK_SOFT, 0.9)
		DrawKit.draw_box_border(self, rect, fill, border, 3 if wrong else 2, 14)
		if placed.is_empty():
			_draw_slot_hint(str(slot.get("hint", "Tempat kosong")), rect)
		else:
			draw_piece(placed, rect.grow(-14.0))


func _draw_slot_hint(text: String, rect: Rect2) -> void:
	var lines := DrawKit.wrap_lines(text, rect.size.x - 16.0, 14)
	var y := rect.get_center().y - float(lines.size() - 1) * 9.0
	for line in lines:
		DrawKit.draw_text_centered(self, Vector2(rect.get_center().x, y), line, 14, Palette.with_alpha(Palette.CREAM_DIM, 0.8))
		y += 18.0


func _draw_tray() -> void:
	var rect := tray_rect()
	DrawKit.draw_box_border(self, rect, Palette.with_alpha(Palette.INK, 0.8), Palette.with_alpha(Palette.CREAM_DARK, 0.4), 2, 14)
	DrawKit.draw_text_centered(self, Vector2(rect.get_center().x, rect.position.y + 20.0), "Potongan tersedia", 15, Palette.CREAM_DARK)
	for piece_id in _unplaced_ids():
		var piece_rect := tray_rect_for(str(piece_id))
		var selected: bool = selected_id == str(piece_id)
		if selected:
			DrawKit.draw_box_border(
				self, piece_rect.grow(6.0), Palette.with_alpha(Palette.GOLD, 0.2), Palette.GOLD, 3, 12
			)
		draw_piece(str(piece_id), piece_rect)
