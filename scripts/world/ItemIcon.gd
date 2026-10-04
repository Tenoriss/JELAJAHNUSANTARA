class_name ItemIcon
extends Node2D
## Ikon barang prosedural yang melayang di dunia (bambu, tali, papan, kain).

@export var kind := "bambu"
@export var tint: Color = Palette.CREAM
@export var animated := true
@export var bob_height := 3.0
@export var glow := true

var _time := 0.0


func setup(new_kind: String, new_tint: Color = Palette.GOLD) -> void:
	kind = new_kind
	tint = new_tint
	queue_redraw()


func _process(delta: float) -> void:
	if not animated:
		return
	_time += delta
	queue_redraw()


func _draw() -> void:
	var bob := sin(_time * 2.0) * bob_height if animated else 0.0
	if glow:
		var pulse := 1.0 + sin(_time * 1.6) * 0.12
		DrawKit.draw_ellipse(self, Vector2(0, 2), Vector2(15.0 * pulse, 6.0 * pulse), Palette.with_alpha(tint, 0.22))
	DrawKit.draw_ellipse(self, Vector2(0, 0), Vector2(10, 3.5), Palette.with_alpha(Color(0.05, 0.04, 0.03, 1.0), 0.25))
	var origin := Vector2(0, bob)
	match kind:
		"bambu":
			_draw_bamboo(origin)
		"rope":
			_draw_rope(origin)
		"plank":
			_draw_plank(origin)
		"cloth":
			_draw_cloth(origin)
		_:
			_draw_bamboo(origin)


func _draw_bamboo(origin: Vector2) -> void:
	for i in 3:
		var offset := Vector2(float(i - 1) * 6.0, float(abs(i - 1)) * 2.0)
		DrawKit.draw_pillar(self, origin + Vector2(offset.x, 2.0), 5.0, 34.0, Palette.BAMBOO, Palette.BAMBOO_DARK)
		for seg in 3:
			DrawKit.draw_box(
				self,
				Rect2(origin.x + offset.x - 2.6, origin.y - 8.0 - float(seg) * 10.0, 5.2, 1.4),
				Palette.BAMBOO_DARK,
				0
			)
	# daun
	DrawKit.draw_ellipse(self, origin + Vector2(-8, -30), Vector2(8, 3), Palette.LEAF)
	DrawKit.draw_ellipse(self, origin + Vector2(9, -34), Vector2(7, 2.8), Palette.LEAF_LIGHT)
	DrawKit.draw_ellipse(self, origin + Vector2(-6, -37), Vector2(6, 2.4), Palette.LEAF_DARK)


func _draw_rope(origin: Vector2) -> void:
	var center := origin + Vector2(0, -14)
	for i in 3:
		var radius := 12.0 - float(i) * 3.4
		DrawKit.draw_ellipse_ring(self, center, Vector2(radius, radius * 0.72), Palette.CREAM_DARK, 3.0, 20)
	DrawKit.draw_ellipse_ring(self, center, Vector2(13.5, 10.0), Palette.PATH_SAND_DARK, 1.4, 22)
	DrawKit.draw_box(self, Rect2(center.x + 8.0, center.y + 4.0, 12.0, 3.0), Palette.CREAM_DARK, 1)


func _draw_plank(origin: Vector2) -> void:
	var rect := Rect2(origin.x - 17.0, origin.y - 26.0, 34.0, 16.0)
	DrawKit.draw_box(self, rect, Palette.WOOD_LIGHT, 3)
	DrawKit.draw_box(self, Rect2(rect.position.x, rect.position.y, rect.size.x, 4.0), Palette.WOOD, 2)
	for i in 3:
		DrawKit.draw_box(
			self, Rect2(rect.position.x + 4.0, rect.position.y + 6.0 + float(i) * 3.4, rect.size.x - 8.0, 1.1), Palette.WOOD, 0
		)
	DrawKit.draw_ellipse(self, Vector2(origin.x - 6.0, origin.y - 20.0), Vector2(2.4, 1.8), Palette.WOOD_DARK)
	DrawKit.draw_ellipse(self, Vector2(origin.x + 8.0, origin.y - 22.0), Vector2(2.0, 1.6), Palette.WOOD_DARK)


func _draw_cloth(origin: Vector2) -> void:
	var rect := Rect2(origin.x - 18.0, origin.y - 30.0, 36.0, 26.0)
	DrawKit.draw_box(self, rect, Palette.INDIGO, 4)
	var pattern := Palette.GOLD_PALE
	for row in 2:
		for column in 3:
			var center := Vector2(
				rect.position.x + 7.0 + float(column) * 11.0, rect.position.y + 8.0 + float(row) * 11.0
			)
			DrawKit.draw_ellipse_ring(self, center, Vector2(4.0, 4.0), pattern, 1.4, 12)
			DrawKit.draw_ellipse(self, center, Vector2(1.3, 1.3), pattern)
	# lipatan kain
	DrawKit.draw_box(self, Rect2(rect.position.x, rect.position.y + 22.0, rect.size.x, 4.0), Palette.with_alpha(Palette.INK, 0.35), 2)
