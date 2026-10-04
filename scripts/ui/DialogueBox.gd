class_name DialogueBox
extends CanvasLayer
## Kotak dialog: nama pembicara, potret, dan teks yang muncul huruf demi huruf.
##
## DialogueManager memanggil show_line() untuk setiap baris dan hide_box()
## ketika percakapan selesai. Pemain menekan SPACE/E untuk melanjutkan;
## Main yang meneruskan tombol tersebut lewat request_advance().

const TYPE_SPEED := 54.0
const PORTRAIT_SIZE := 116

@onready var root: Control = $Root
@onready var box: Panel = $Root/Box
@onready var name_label: Label = $Root/Box/Margin/Columns/Lines/NameLabel
@onready var text_label: RichTextLabel = $Root/Box/Margin/Columns/Lines/TextLabel
@onready var hint_label: Label = $Root/Box/Margin/Columns/Lines/HintLabel
@onready var portrait: TextureRect = $Root/Box/Margin/Columns/Portrait

var _portraits: Dictionary = {}
var _typing := false
var _typed := 0.0
var _total := 0
var _tween: Tween
var _base_top := 0.0
var _base_bottom := 0.0
## Baris narasi (pembuka/penutup) punya "pause": lanjut sendiri seperti film.
var _auto_delay := -1.0
var _auto_timer := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_base_top = box.offset_top
	_base_bottom = box.offset_bottom
	box.visible = false
	root.visible = true
	DialogueManager.register_box(self)
	set_process(false)


# --- Dipanggil DialogueManager --------------------------------------------

func show_line(line: Dictionary, has_more: bool) -> void:
	var speaker := str(line.get("speaker", ""))
	var narration := bool(line.get("narration", false)) or speaker.is_empty()
	var text := str(line.get("text", ""))

	name_label.visible = not narration
	portrait.visible = false
	if not narration:
		name_label.text = speaker
		name_label.add_theme_color_override(
			"font_color", UiKit.color_from(line.get("color", ""), Palette.GOLD)
		)
		var portrait_id := str(line.get("portrait", ""))
		if not portrait_id.is_empty():
			portrait.texture = _portrait(portrait_id)
			portrait.visible = true
	else:
		name_label.text = ""

	text_label.add_theme_color_override(
		"default_color", Palette.CREAM_DIM if narration else Palette.CREAM
	)
	text_label.text = text
	hint_label.text = "SPACE lanjut  ▸" if has_more else "SPACE tutup  ✕"
	_auto_delay = float(line.get("pause", -1.0))
	_auto_timer = 0.0
	_start_typing(text)
	_pop_in()


func hide_box() -> void:
	_typing = false
	_auto_delay = -1.0
	set_process(false)
	if _tween != null and _tween.is_valid():
		_tween.kill()
	box.visible = false
	portrait.visible = false


## Meneruskan tekanan tombol dari Main. Mengembalikan true bila tombol dipakai.
func request_advance() -> bool:
	if not DialogueManager.is_active:
		return false
	if _typing:
		_finish_typing()
		return true
	DialogueManager.advance()
	return true


func is_typing() -> bool:
	return _typing


# --- Pengetikan -----------------------------------------------------------

func _start_typing(text: String) -> void:
	box.visible = true
	_typing = true
	_typed = 0.0
	_total = text.length()
	text_label.visible_characters = 0
	set_process(true)


func _process(delta: float) -> void:
	if _typing:
		_typed += delta * TYPE_SPEED
		if int(_typed) >= _total:
			_finish_typing()
		else:
			text_label.visible_characters = int(_typed)
			hint_label.modulate.a = 0.35
		return
	if _auto_delay > 0.0:
		_auto_timer += delta
		if _auto_timer >= _auto_delay:
			_auto_delay = -1.0
			DialogueManager.advance()


func _finish_typing() -> void:
	_typing = false
	text_label.visible_characters = -1
	hint_label.modulate.a = 1.0
	if _auto_delay <= 0.0:
		set_process(false)


func _pop_in() -> void:
	box.modulate = Color(1, 1, 1, 0)
	box.offset_top = _base_top + 20.0
	box.offset_bottom = _base_bottom + 20.0
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(box, "modulate:a", 1.0, 0.14)
	_tween.tween_property(box, "offset_top", _base_top, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(box, "offset_bottom", _base_bottom, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _portrait(character_id: String) -> Texture2D:
	if _portraits.has(character_id):
		return _portraits[character_id]
	var texture := TextureFactory.portrait(character_id, PORTRAIT_SIZE)
	_portraits[character_id] = texture
	return texture
