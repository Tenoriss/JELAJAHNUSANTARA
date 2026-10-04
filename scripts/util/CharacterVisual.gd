class_name CharacterVisual
extends Node2D
## Visual karakter prosedural untuk Raka, NPC, dan warga desa.
##
## Karakter digambar dari bentuk dasar: bayangan, kaki, badan, tangan, kepala,
## dan rambut. Animasi berjalan memakai `walk_phase`, animasi diam memakai
## napas naik-turun halus.

@export var palette_id := "raka":
	set(value):
		palette_id = value
		_palette = Palette.character(palette_id)
		_apply_scale()
		queue_redraw()

## Arah pandang (bebas, akan dinormalisasi saat menggambar).
@export var facing := Vector2.DOWN
## 0.0 = diam, 1.0 = bergerak penuh.
@export var speed_ratio := 0.0
@export var walk_phase := 0.0
## Menonaktifkan animasi (mis. untuk potret statis).
@export var animated := true

var _palette: Dictionary = {}
var _idle_time := 0.0
var _step_phase := 0.0


func _ready() -> void:
	_palette = Palette.character(palette_id)
	_apply_scale()
	z_index = 1


func _apply_scale() -> void:
	var factor := float(_palette.get("scale", 1.0))
	scale = Vector2(factor, factor)


func _process(delta: float) -> void:
	if not animated:
		return
	_idle_time += delta
	if speed_ratio > 0.05:
		_step_phase += delta * (6.5 + 5.0 * speed_ratio)
	walk_phase = _step_phase
	queue_redraw()


## Menghadap ke sebuah titik dunia (dipakai NPC agar menoleh ke pemain).
func face_towards(point: Vector2) -> void:
	var delta := point - global_position
	if delta.length() > 4.0:
		facing = delta.normalized()


func _draw() -> void:
	if _palette.is_empty():
		return
	var moving := speed_ratio > 0.05
	var swing := sin(walk_phase) if moving else 0.0
	var bob := sin(_idle_time * 2.4) * 0.8 - absf(swing) * 1.2 * speed_ratio
	var back_view := facing.y < -0.5 and absf(facing.x) < 0.7
	var side_view := absf(facing.x) >= 0.5
	var side_dir := 1.0 if facing.x >= 0.0 else -1.0

	_draw_shadow()
	_draw_legs(swing, side_dir, side_view)
	_draw_body(bob, back_view)
	_draw_arms(swing, bob, side_view, side_dir)
	_draw_head(bob, back_view, side_view, side_dir)


func _draw_shadow() -> void:
	DrawKit.draw_shadow(self, Vector2(0, 0), Vector2(13, 5), 0.22)


func _draw_legs(swing: float, side_dir: float, side_view: bool) -> void:
	var skin: Color = _palette["skin"]
	var lower: Color = _palette["lower"]
	var shoes: Color = _palette["shoes"]
	var front := -swing * 3.0
	var back := swing * 3.0
	for i in 2:
		var offset: float = (-5.0 if i == 0 else 5.0)
		if side_view:
			offset *= 0.6
		var step := front if i == 0 else back
		DrawKit.draw_box(self, Rect2(offset - 3.0, -14.0 + step * 0.35, 6.0, 10.0), lower, 3)
		DrawKit.draw_box(self, Rect2(offset - 3.5, -5.0 + step * 0.5, 7.0, 5.0), shoes, 2)
	# garis singkat bawah badan (kain)
	DrawKit.draw_box(self, Rect2(-8.0, -17.0, 16.0, 4.0), skin.darkened(0.1), 2)


func _draw_body(bob: float, back_view: bool) -> void:
	var shirt: Color = _palette["shirt"]
	var shirt_dark: Color = _palette["shirt_dark"]
	var accent: Color = _palette["accent"]
	var lower: Color = _palette["lower"]
	var style := str(_palette.get("style", "young"))

	# rok/kain panjang (kebaya) atau celana
	if bool(_palette.get("skirt", false)):
		var skirt := PackedVector2Array(
			[
				Vector2(-9.0, -32.0 + bob),
				Vector2(9.0, -32.0 + bob),
				Vector2(13.0, -6.0 + bob),
				Vector2(-13.0, -6.0 + bob),
			]
		)
		DrawKit.draw_poly(self, skirt, lower)
		DrawKit.draw_box(self, Rect2(-9.5, -33.0 + bob, 19.0, 12.0), shirt, 4)
	else:
		DrawKit.draw_box(self, Rect2(-10.0, -14.0 + bob, 20.0, 12.0), lower, 4)
		DrawKit.draw_box(self, Rect2(-10.0, -33.0 + bob, 20.0, 20.0), shirt, 5)

	# bagian bawah baju yang lebih gelap
	DrawKit.draw_box(self, Rect2(-10.0, -14.0 + bob, 20.0, 4.0), shirt_dark, 2)
	# selendang / sabuk
	if style == "woman" or bool(_palette.get("scarf", false)):
		DrawKit.draw_box(self, Rect2(-10.5, -26.0 + bob, 21.0, 4.0), accent, 2)
	else:
		DrawKit.draw_box(self, Rect2(-10.5, -18.0 + bob, 21.0, 3.0), accent, 1)

	if style == "craftsman":
		# celemek kerja
		DrawKit.draw_box(self, Rect2(-7.0, -28.0 + bob, 14.0, 14.0), Palette.WOOD_LIGHT, 3)
	if style == "youth":
		# saku jaket
		DrawKit.draw_box(self, Rect2(-9.0 if not back_view else 2.0, -27.0 + bob, 6.0, 5.0), shirt_dark, 2)
	if style == "child":
		DrawKit.draw_box(self, Rect2(-9.0, -30.0 + bob, 18.0, 4.0), accent, 2)


func _draw_arms(swing: float, bob: float, side_view: bool, side_dir: float) -> void:
	var skin: Color = _palette["skin"]
	var shirt: Color = _palette["shirt"]
	var accent: Color = _palette["accent"]
	var style := str(_palette.get("style", "young"))
	var spread := 11.0 if not side_view else 8.0
	for i in 2:
		var direction := -1.0 if i == 0 else 1.0
		var offset := direction * spread
		var arm_swing := (-swing if i == 0 else swing) * 2.2
		DrawKit.draw_box(self, Rect2(offset - 3.0 + arm_swing * 0.2, -32.0 + bob, 6.0, 9.0), shirt, 3)
		DrawKit.draw_box(self, Rect2(offset - 2.6 + arm_swing * 0.2, -24.5 + bob + arm_swing * 0.3, 5.2, 8.0), skin, 2)
	# tongkat untuk sesepuh
	if style == "elder":
		DrawKit.draw_pillar(self, Vector2(side_dir * 13.0, 2.0), 2.6, 32.0, Palette.WOOD_DARK)
	# keranjang untuk pembawa bakul
	if style == "woman" and bool(_palette.get("bun", false)):
		DrawKit.draw_box(self, Rect2(side_dir * 11.0, -20.0 + bob, 10.0, 8.0), Palette.PATH_SAND_DARK, 3)
		DrawKit.draw_ellipse_ring(
			self, Vector2(side_dir * 16.0, -21.0 + bob), Vector2(5.0, 4.0), accent, 1.5, 14
		)


func _draw_head(bob: float, back_view: bool, side_view: bool, side_dir: float) -> void:
	var skin: Color = _palette["skin"]
	var hair: Color = _palette["hair"]
	var head_center := Vector2(0, -41.0 + bob)
	DrawKit.draw_ellipse(self, head_center, Vector2(9.5, 10.0), skin)
	# leher
	DrawKit.draw_box(self, Rect2(-3.5, -33.5 + bob, 7.0, 4.0), skin.darkened(0.15), 1)

	var hat := str(_palette.get("hat", ""))
	if hat == "straw":
		DrawKit.draw_ellipse(self, Vector2(0, -47.0 + bob), Vector2(17.0, 5.0), Palette.PATH_SAND)
		DrawKit.draw_ellipse(self, Vector2(0, -50.0 + bob), Vector2(10.0, 6.5), Palette.PATH_SAND_DARK)
	elif hat == "cap":
		DrawKit.draw_ellipse(self, Vector2(0, -46.0 + bob), Vector2(10.0, 7.0), hair)
		DrawKit.draw_ellipse(self, Vector2(side_dir * 6.0, -46.0 + bob), Vector2(7.0, 3.0), Palette.FABRIC_RED)
	elif back_view:
		DrawKit.draw_ellipse(self, Vector2(0, -43.0 + bob), Vector2(9.8, 9.0), hair)
	else:
		DrawKit.draw_ellipse(self, Vector2(0, -45.5 + bob), Vector2(9.8, 7.0), hair)
	if bool(_palette.get("bun", false)) and hat == "":
		DrawKit.draw_ellipse(self, Vector2(0, -51.0 + bob), Vector2(4.0, 3.6), hair)

	if back_view:
		return

	# mata
	var eye_color := Palette.HAIR_DARK
	var eye_y := -41.0 + bob
	if side_view:
		DrawKit.draw_ellipse(self, Vector2(side_dir * 3.5, eye_y), Vector2(1.6, 2.0), eye_color)
	else:
		DrawKit.draw_ellipse(self, Vector2(-3.4, eye_y), Vector2(1.6, 2.0), eye_color)
		DrawKit.draw_ellipse(self, Vector2(3.4, eye_y), Vector2(1.6, 2.0), eye_color)
	# mulut kecil
	if not side_view:
		DrawKit.draw_ellipse(self, Vector2(0, -35.5 + bob), Vector2(2.2, 1.1), skin.darkened(0.35))
