class_name VillageGround
extends Node2D
## Menggambar tanah Desa Arunika: rumput, jalan setapak, alun-alun, sawah,
## kolam, dan kebun.
##
## Semua bentuk berasal dari data yang diisi di scene (rect), sehingga tata
## letak desa tetap bisa diubah lewat Inspector tanpa menyentuh kode ini.
## Penggambaran hanya terjadi sekali (statis), jadi tidak membebani frame.

@export var map_bounds := Rect2(0, 0, 3200, 2000)
@export var paths: Array[Rect2] = []
@export var plazas: Array[Rect2] = []
@export var paddies: Array[Rect2] = []
@export var ponds: Array[Rect2] = []
@export var gardens: Array[Rect2] = []
@export var open_soil: Array[Rect2] = []
@export var flower_patches: Array[Rect2] = []
@export var seed_value := 20261015
@export var grass_details := true
@export var detail_strength := 1.0

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	z_index = -100
	_rng.seed = seed_value
	queue_redraw()


func _draw() -> void:
	_draw_base_grass()
	if grass_details:
		_draw_grass_details()
	_draw_open_soil()
	_draw_paths()
	_draw_plazas()
	_draw_gardens()
	_draw_ponds()
	_draw_paddies()
	_draw_flowers()
	_draw_border()


func _point_on_feature(point: Vector2) -> bool:
	for rect in paths:
		if rect.has_point(point):
			return true
	for rect in plazas:
		if rect.has_point(point):
			return true
	for rect in paddies:
		if rect.has_point(point):
			return true
	for rect in ponds:
		if rect.has_point(point):
			return true
	for rect in gardens:
		if rect.has_point(point):
			return true
	for rect in open_soil:
		if rect.has_point(point):
			return true
	return false


func _draw_base_grass() -> void:
	draw_rect(map_bounds, Palette.GRASS, true)
	_rng.seed = seed_value + 1
	for i in 46:
		var center := Vector2(
			_rng.randf_range(map_bounds.position.x, map_bounds.end.x),
			_rng.randf_range(map_bounds.position.y, map_bounds.end.y)
		)
		var radii := Vector2(_rng.randf_range(120.0, 330.0), _rng.randf_range(90.0, 220.0))
		var color := Palette.GRASS_DARK if i % 2 == 0 else Palette.GRASS_LIGHT
		DrawKit.draw_ellipse(self, center, radii, Palette.with_alpha(color, 0.35), 18)


func _draw_grass_details() -> void:
	_rng.seed = seed_value + 2
	var count := int(760.0 * detail_strength)
	for i in count:
		var point := Vector2(
			_rng.randf_range(map_bounds.position.x + 10.0, map_bounds.end.x - 10.0),
			_rng.randf_range(map_bounds.position.y + 10.0, map_bounds.end.y - 10.0)
		)
		if _point_on_feature(point):
			continue
		var color := Palette.GRASS_DARK if i % 3 != 0 else Palette.LEAF_LIGHT
		var height := _rng.randf_range(4.0, 8.0)
		draw_line(point, point + Vector2(_rng.randf_range(-1.6, 1.6), -height), color, 1.4, true)


func _draw_open_soil() -> void:
	for rect in open_soil:
		DrawKit.draw_box(self, rect, Palette.SOIL, 10)
		DrawKit.draw_box(self, rect.grow(-6.0), Palette.SOIL_DARK, 8)
		DrawKit.draw_box(self, rect.grow(-10.0), Palette.SOIL, 6)
	_rng.seed = seed_value + 3
	for rect in open_soil:
		for i in 8:
			var point := Vector2(
				_rng.randf_range(rect.position.x + 8.0, rect.end.x - 8.0),
				_rng.randf_range(rect.position.y + 8.0, rect.end.y - 8.0)
			)
			DrawKit.draw_ellipse(self, point, Vector2(3.0, 2.0), Palette.with_alpha(Palette.SOIL_DARK, 0.5))


func _draw_paths() -> void:
	for rect in paths:
		DrawKit.draw_box(self, rect.grow(6.0), Palette.PATH_SAND_DARK, 18)
		DrawKit.draw_box(self, rect, Palette.PATH_SAND, 16)
	_rng.seed = seed_value + 4
	for rect in paths:
		var pebbles := int(maxf(3.0, rect.size.x * rect.size.y / 9000.0))
		for i in pebbles:
			var point := Vector2(
				_rng.randf_range(rect.position.x, rect.end.x), _rng.randf_range(rect.position.y, rect.end.y)
			)
			DrawKit.draw_ellipse(
				self, point, Vector2(_rng.randf_range(1.6, 3.4), _rng.randf_range(1.2, 2.4)),
				Palette.with_alpha(Palette.PATH_SAND_DARK, 0.75)
			)


func _draw_plazas() -> void:
	_rng.seed = seed_value + 5
	for rect in plazas:
		DrawKit.draw_box(self, rect.grow(8.0), Palette.PATH_SAND_DARK, 22)
		DrawKit.draw_box(self, rect, Palette.PATH_STONE, 20)
		var tile := 46.0
		var columns := int(rect.size.x / tile)
		var rows := int(rect.size.y / tile)
		for row in rows:
			for column in columns:
				var center := rect.position + Vector2(
					(0.5 + float(column)) * rect.size.x / float(columns),
					(0.5 + float(row)) * rect.size.y / float(rows)
				)
				var radii := Vector2(
					_rng.randf_range(16.0, 20.0) * (rect.size.x / float(columns)) / tile,
					_rng.randf_range(12.0, 15.0) * (rect.size.y / float(rows)) / tile
				)
				DrawKit.draw_ellipse(self, center, radii, Palette.with_alpha(Palette.STONE, 0.55), 10)
			if rows > 6:
				break


func _draw_gardens() -> void:
	_rng.seed = seed_value + 6
	for rect in gardens:
		DrawKit.draw_box(self, rect.grow(5.0), Palette.SOIL_DARK, 8)
		DrawKit.draw_box(self, rect, Palette.SOIL, 6)
		var rows := int(maxf(2.0, rect.size.y / 34.0))
		for row in rows:
			var y := rect.position.y + (0.5 + float(row)) * rect.size.y / float(rows)
			DrawKit.draw_line_soft(
				self, Vector2(rect.position.x + 6.0, y), Vector2(rect.end.x - 6.0, y), Palette.SOIL_DARK, 2.0
			)
			var plants := int(maxf(2.0, rect.size.x / 34.0))
			for plant in plants:
				var x := rect.position.x + (0.5 + float(plant)) * rect.size.x / float(plants)
				var height := _rng.randf_range(7.0, 13.0)
				draw_line(Vector2(x, y), Vector2(x, y - height), Palette.LEAF_DARK, 2.0, true)
				draw_line(
					Vector2(x - 3.0, y - height * 0.6), Vector2(x + 3.0, y - height * 0.6), Palette.LEAF, 2.0, true
				)


func _draw_ponds() -> void:
	for rect in ponds:
		DrawKit.draw_box(self, rect.grow(6.0), Palette.SOIL_DARK, 16)
		DrawKit.draw_box(self, rect, Palette.WATER_DEEP, 14)
		DrawKit.draw_box(self, rect.grow(-8.0), Palette.WATER, 12)
		DrawKit.draw_ellipse(
			self, rect.get_center() + Vector2(-rect.size.x * 0.16, -rect.size.y * 0.14),
			Vector2(rect.size.x * 0.26, rect.size.y * 0.16), Palette.with_alpha(Palette.CREAM, 0.22)
		)
	_rng.seed = seed_value + 7
	for rect in ponds:
		for i in 5:
			var point := Vector2(
				_rng.randf_range(rect.position.x + 12.0, rect.end.x - 12.0),
				_rng.randf_range(rect.position.y + 12.0, rect.end.y - 12.0)
			)
			DrawKit.draw_ellipse(self, point, Vector2(7.0, 2.0), Palette.with_alpha(Palette.CREAM, 0.25))


func _draw_paddies() -> void:
	_rng.seed = seed_value + 8
	for rect in paddies:
		# pematang (pematang = dike) di sekeliling petak
		DrawKit.draw_box(self, rect.grow(7.0), Palette.SOIL, 12)
		DrawKit.draw_box(self, rect, Palette.PADDY_WATER, 10)
		DrawKit.draw_box(self, rect.grow(-5.0), Palette.with_alpha(Palette.PADDY_WATER, 0.85), 8)
		var rows := int(maxf(3.0, rect.size.y / 30.0))
		for row in rows:
			var y := rect.position.y + (0.4 + float(row)) * rect.size.y / float(rows)
			var plants := int(maxf(3.0, rect.size.x / 26.0))
			for plant in plants:
				var x := rect.position.x + (0.5 + float(plant)) * rect.size.x / float(plants)
				var jitter := _rng.randf_range(-3.0, 3.0)
				var height := _rng.randf_range(9.0, 15.0)
				var color := Palette.RICE_GREEN if (row + plant) % 3 != 0 else Palette.RICE_GOLD
				draw_line(Vector2(x, y + 2.0), Vector2(x + jitter, y - height), color, 2.2, true)
				draw_line(
					Vector2(x, y + 2.0),
					Vector2(x + jitter * 0.4 - 3.0, y - height * 0.5),
					color.darkened(0.1),
					1.6,
					true
				)
		# kilau air
		DrawKit.draw_ellipse(
			self,
			rect.get_center() + Vector2(0, rect.size.y * 0.3),
			Vector2(rect.size.x * 0.3, rect.size.y * 0.08),
			Palette.with_alpha(Palette.CREAM, 0.18)
		)


func _draw_flowers() -> void:
	_rng.seed = seed_value + 9
	var colors := [Palette.ROSE, Palette.GOLD, Palette.CREAM, Palette.PLUM, Palette.FABRIC_YELLOW]
	for rect in flower_patches:
		var count := int(maxf(6.0, rect.size.x * rect.size.y / 2600.0))
		for i in count:
			var point := Vector2(
				_rng.randf_range(rect.position.x, rect.end.x), _rng.randf_range(rect.position.y, rect.end.y)
			)
			if _point_on_feature(point):
				continue
			var color: Color = colors[_rng.randi_range(0, colors.size() - 1)]
			draw_line(point, point + Vector2(0, -4.0), Palette.GRASS_DARK, 1.2, true)
			DrawKit.draw_ellipse(self, point + Vector2(0, -5.0), Vector2(2.6, 2.2), color, 8)


func _draw_border() -> void:
	var thick := 46.0
	var dark := Palette.GRASS_DARK.darkened(0.25)
	var rects := [
		Rect2(map_bounds.position, Vector2(map_bounds.size.x, thick)),
		Rect2(Vector2(map_bounds.position.x, map_bounds.end.y - thick), Vector2(map_bounds.size.x, thick)),
		Rect2(map_bounds.position, Vector2(thick, map_bounds.size.y)),
		Rect2(Vector2(map_bounds.end.x - thick, map_bounds.position.y), Vector2(thick, map_bounds.size.y)),
	]
	for rect in rects:
		DrawKit.draw_box(self, rect, dark, 0)
