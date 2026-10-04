class_name InteractPrompt
extends Node2D
## Balon petunjuk di atas objek: "E · Bicara dengan Mbah Seno".

const FONT_SIZE := 17
const PADDING := Vector2(12.0, 8.0)
const ICON_SIZE := 24.0

var _source: Interactable = null
var _pop := 1.0


func configure(source: Interactable) -> void:
	_source = source
	z_index = 60
	top_level = false
	set_process(false)
	queue_redraw()


func pop_in() -> void:
	_pop = 0.62
	set_process(true)


func _process(delta: float) -> void:
	_pop = move_toward(_pop, 1.0, delta * 4.0)
	if is_equal_approx(_pop, 1.0):
		set_process(false)
	queue_redraw()


func _draw() -> void:
	if _source == null:
		return
	var text := _source.get_prompt_text()
	var icon := _source.get_prompt_icon()
	var text_size := DrawKit.text_size(text, FONT_SIZE)
	var width := ICON_SIZE + PADDING.x * 3.0 + text_size.x
	var height := maxf(text_size.y + PADDING.y * 2.0, ICON_SIZE + PADDING.y * 2.0)
	var rect := Rect2(-width * 0.5, -height, width, height)

	draw_set_transform(Vector2(0, 0), 0.0, Vector2(_pop, _pop))
	DrawKit.draw_box_border(self, rect, Palette.with_alpha(Palette.INK, 0.92), Palette.GOLD, 2, 10)
	# ekor balon
	DrawKit.draw_poly(
		self,
		PackedVector2Array(
			[
				Vector2(-6, rect.end.y - 1.0),
				Vector2(6, rect.end.y - 1.0),
				Vector2(0, rect.end.y + 7.0),
			]
		),
		Palette.with_alpha(Palette.INK, 0.92)
	)
	# lencana tombol
	var badge := Rect2(rect.position.x + PADDING.x * 0.5, rect.position.y + (height - ICON_SIZE) * 0.5, ICON_SIZE, ICON_SIZE)
	DrawKit.draw_box(self, badge, Palette.GOLD, 6)
	DrawKit.draw_text_centered(self, badge.get_center() + Vector2(0, 1), "E", 15, Palette.INK)
	# teks
	var label_pos := Vector2(badge.end.x + PADDING.x * 0.8, rect.position.y + height * 0.5)
	DrawKit.draw_text_wrapped(
		self, Vector2(label_pos.x, rect.position.y + PADDING.y * 0.4), text, 1000.0, FONT_SIZE, Palette.CREAM
	)
	draw_set_transform(Vector2(0, 0), 0.0, Vector2.ONE)
