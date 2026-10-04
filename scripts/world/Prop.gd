class_name Prop
extends Node2D
## Properti lingkungan digambar dengan kode (tanpa aset gambar).
##
## Origin setiap prop berada di titik dasarnya (menyentuh tanah), sehingga
## Y-sort antar prop, NPC, dan pemain berjalan otomatis.

# Ukuran default per jenis prop (lebar x tinggi dalam piksel). Bila `size`
# dibiarkan (0, 0) maka nilai dari tabel ini yang dipakai.
const DEFAULT_SIZES := {
	"house": Vector2(156, 126),
	"house_small": Vector2(112, 96),
	"balai": Vector2(268, 176),
	"workshop": Vector2(216, 142),
	"saung": Vector2(124, 122),
	"stage": Vector2(300, 132),
	"gapura": Vector2(176, 148),
	"tree": Vector2(116, 132),
	"palm": Vector2(92, 154),
	"bamboo_clump": Vector2(84, 152),
	"well": Vector2(72, 74),
	"bench": Vector2(62, 36),
	"lamp": Vector2(34, 122),
	"table": Vector2(84, 48),
	"crate": Vector2(42, 42),
	"wood_stack": Vector2(72, 46),
	"tools": Vector2(48, 24),
	"cart": Vector2(88, 62),
	"basket": Vector2(36, 32),
	"barrel": Vector2(42, 48),
	"rice_sheaf": Vector2(42, 48),
	"scarecrow": Vector2(56, 104),
	"flower_bush": Vector2(48, 36),
	"grass_tuft": Vector2(30, 20),
	"rock": Vector2(46, 28),
	"lily": Vector2(32, 16),
	"fence": Vector2(124, 42),
	"banner": Vector2(28, 152),
	"fire_pit": Vector2(64, 32),
	"sign_post": Vector2(46, 92),
}

## Jenis yang tidak menghalangi pemain.
const SOFT_KINDS := ["grass_tuft", "flower_bush", "lily", "tools", "rice_sheaf"]

const COLLISION := {
	"tree": Vector2(0.32, 0.14),
	"palm": Vector2(0.26, 0.1),
	"bamboo_clump": Vector2(0.34, 0.12),
	"well": Vector2(0.74, 0.3),
	"lamp": Vector2(0.3, 0.08),
	"banner": Vector2(0.25, 0.06),
	"fence": Vector2(1.0, 0.12),
	"stage": Vector2(0.9, 0.3),
	"balai": Vector2(0.88, 0.22),
	"saung": Vector2(0.42, 0.16),
	"gapura": Vector2(0.9, 0.16),
	"fire_pit": Vector2(0.7, 0.28),
	"scarecrow": Vector2(0.3, 0.1),
	"sign_post": Vector2(0.22, 0.3),
	"rock": Vector2(0.8, 0.5),
	"bench": Vector2(0.9, 0.36),
	"table": Vector2(0.9, 0.3),
	"cart": Vector2(0.86, 0.34),
}

@export var kind := "tree":
	set(value):
		kind = value
		queue_redraw()

## Kosongkan (0, 0) untuk memakai ukuran default jenis prop.
@export var size := Vector2.ZERO:
	set(value):
		size = value
		queue_redraw()

@export var variant := 0
@export var tint := Color(1, 1, 1, 1)
@export var sway := false
@export var solid := true
## 0.0 - 1.0, untuk lampu yang menyala saat senja.
@export var glow := 0.0:
	set(value):
		glow = value
		# Lampu yang menyala digambar di atas prop lain, juga saat glow diubah
		# dari kode (Village menyalakan lampu ketika acara siap).
		if value > 0.0:
			z_index = 2
		queue_redraw()

var _time := 0.0


func _ready() -> void:
	if kind in SOFT_KINDS:
		solid = false
	_apply_collision()
	if sway:
		set_process(true)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func effective_size() -> Vector2:
	if size.x > 1.0 and size.y > 1.0:
		return size
	return DEFAULT_SIZES.get(kind, Vector2(64, 64))


func _apply_collision() -> void:
	var body := get_node_or_null("Body") as StaticBody2D
	var shape_node := get_node_or_null("Body/Shape") as CollisionShape2D
	if body == null or shape_node == null:
		return
	if not solid:
		body.process_mode = Node.PROCESS_MODE_DISABLED
		body.collision_layer = 0
		return
	var dims := effective_size()
	var profile: Vector2 = COLLISION.get(kind, Vector2(0.86, 0.26))
	var collision_size := Vector2(maxf(dims.x * profile.x, 8.0), maxf(dims.y * profile.y, 8.0))
	# Selalu buat shape baru: sub-resource pada scene berbagi antar instance,
	# jadi mengubah size di satu prop akan ikut mengubah prop lain.
	var rect := RectangleShape2D.new()
	rect.size = collision_size
	shape_node.shape = rect
	shape_node.position = Vector2(0, -collision_size.y * 0.5)


func _draw() -> void:
	var dims := effective_size()
	var palette := tint
	var bob := sin(_time * 1.1 + position.x * 0.01) * 1.6 if sway else 0.0
	match kind:
		"house", "house_small":
			_draw_house(dims, palette, sway)
		"balai":
			_draw_balai(dims, palette)
		"workshop":
			_draw_workshop(dims, palette)
		"saung":
			_draw_saung(dims, palette)
		"stage":
			_draw_stage(dims, palette)
		"gapura":
			_draw_gapura(dims, palette)
		"tree":
			_draw_tree(dims, palette, bob)
		"palm":
			_draw_palm(dims, palette, bob)
		"bamboo_clump":
			_draw_bamboo_clump(dims, palette, bob)
		"well":
			_draw_well(dims, palette)
		"bench":
			_draw_bench(dims, palette)
		"lamp":
			_draw_lamp(dims, palette)
		"table":
			_draw_table(dims, palette)
		"crate":
			_draw_crate(dims, palette)
		"wood_stack":
			_draw_wood_stack(dims, palette)
		"tools":
			_draw_tools(dims, palette)
		"cart":
			_draw_cart(dims, palette)
		"basket":
			_draw_basket(dims, palette)
		"barrel":
			_draw_barrel(dims, palette)
		"rice_sheaf":
			_draw_rice_sheaf(dims, palette)
		"scarecrow":
			_draw_scarecrow(dims, palette, bob)
		"flower_bush":
			_draw_flower_bush(dims, palette, bob)
		"grass_tuft":
			_draw_grass_tuft(dims, palette, bob)
		"rock":
			_draw_rock(dims, palette)
		"lily":
			_draw_lily(dims, palette)
		"fence":
			_draw_fence(dims, palette)
		"banner":
			_draw_banner(dims, palette, bob)
		"fire_pit":
			_draw_fire_pit(dims, palette)
		"sign_post":
			_draw_sign_post(dims, palette)
		_:
			DrawKit.draw_box(self, Rect2(-dims.x * 0.5, -dims.y * 0.5, dims.x, dims.y), Palette.WOOD_LIGHT, 6)


# --- Rumah & bangunan ----------------------------------------------------

func _wall_color() -> Color:
	match variant % 4:
		0:
			return Palette.CREAM_DIM
		1:
			return Color(0.9137, 0.8509, 0.7412, 1.0)
		2:
			return Palette.WOOD_LIGHT
		_:
			return Color(0.8706, 0.8196, 0.7020, 1.0)


func _roof_color() -> Color:
	match variant % 4:
		0:
			return Palette.ROOF_TILE
		1:
			return Palette.TERRACOTTA
		2:
			return Palette.WOOD_DARK
		_:
			return Palette.ROOF_SHADOW


func _draw_house(dims: Vector2, palette: Color, do_sway: bool) -> void:
	var width := dims.x
	var height := dims.y
	var wall_h := height * 0.5
	var roof_h := height * 0.42
	var wall := _wall_color() * palette
	var roof := _roof_color() * palette
	DrawKit.draw_shadow(self, Vector2(0, 0), Vector2(width * 0.5, height * 0.1), 0.22)
	# badan rumah
	DrawKit.draw_box(self, Rect2(-width * 0.42, -wall_h, width * 0.84, wall_h), wall, 4)
	DrawKit.draw_box(self, Rect2(-width * 0.42, -wall_h, width * 0.84, 5.0), wall.darkened(0.18), 2)
	# atap bertingkat
	var roof_points := PackedVector2Array(
		[
			Vector2(-width * 0.56, -wall_h),
			Vector2(width * 0.56, -wall_h),
			Vector2(width * 0.38, -wall_h - roof_h * 0.72),
			Vector2(-width * 0.38, -wall_h - roof_h * 0.72),
		]
	)
	DrawKit.draw_poly(self, roof_points, roof)
	DrawKit.draw_poly(
		self,
		PackedVector2Array(
			[
				Vector2(-width * 0.38, -wall_h - roof_h * 0.72),
				Vector2(width * 0.38, -wall_h - roof_h * 0.72),
				Vector2(0, -wall_h - roof_h),
			]
		),
		roof.lightened(0.08)
	)
	for i in 3:
		var line_y := -wall_h - roof_h * (0.18 + 0.24 * float(i))
		DrawKit.draw_line_soft(
			self, Vector2(-width * 0.5, line_y), Vector2(width * 0.5, line_y), roof.darkened(0.16), 1.2
		)
	# pintu & jendela
	var door_w := width * 0.16
	DrawKit.draw_box(self, Rect2(-door_w * 0.5, -wall_h * 0.62, door_w, wall_h * 0.62), Palette.WOOD_DARK, 2)
	DrawKit.draw_box(self, Rect2(-door_w * 0.5, -wall_h * 0.62, door_w, 3.0), Palette.WOOD, 1)
	for side in [-1.0, 1.0]:
		var window := Rect2(side * width * 0.26 - 9.0, -wall_h * 0.72, 18.0, 14.0)
		DrawKit.draw_box(self, window, Palette.FABRIC_BLUE.darkened(0.25), 2)
		DrawKit.draw_line_soft(self, window.position, window.end, Palette.CREAM_DIM, 1.4)
	# teras kecil
	DrawKit.draw_box(self, Rect2(-width * 0.3, -2.0, width * 0.6, 4.0), Palette.WOOD, 2)


func _draw_balai(dims: Vector2, palette: Color) -> void:
	var width := dims.x
	var height := dims.y
	var floor_h := height * 0.22
	var wall_h := height * 0.34
	var roof := _roof_color() * palette
	DrawKit.draw_shadow(self, Vector2(0, 0), Vector2(width * 0.5, height * 0.08), 0.24)
	# lantai panggung
	DrawKit.draw_box(self, Rect2(-width * 0.46, -floor_h, width * 0.92, floor_h), Palette.WOOD_LIGHT, 4)
	DrawKit.draw_box(self, Rect2(-width * 0.46, -floor_h, width * 0.92, 4.0), Palette.WOOD_DARK, 2)
	# dinding belakang
	DrawKit.draw_box(self, Rect2(-width * 0.34, -floor_h - wall_h, width * 0.68, wall_h), _wall_color() * palette, 4)
	# tiang
	for i in 5:
		var x := lerpf(-width * 0.44, width * 0.44, float(i) / 4.0)
		DrawKit.draw_pillar(self, Vector2(x, -floor_h), 7.0, wall_h * 0.95, Palette.WOOD, Palette.WOOD_LIGHT)
	# atap limasan
	var roof_y := -floor_h - wall_h
	var points := PackedVector2Array(
		[
			Vector2(-width * 0.58, roof_y),
			Vector2(width * 0.58, roof_y),
			Vector2(width * 0.3, roof_y - height * 0.42),
			Vector2(-width * 0.3, roof_y - height * 0.42),
		]
	)
	DrawKit.draw_poly(self, points, roof)
	DrawKit.draw_poly(
		self,
		PackedVector2Array(
			[
				Vector2(-width * 0.3, roof_y - height * 0.42),
				Vector2(width * 0.3, roof_y - height * 0.42),
				Vector2(0, roof_y - height * 0.6),
			]
		),
		roof.lightened(0.1)
	)
	# tulisan kecil di balok atas
	DrawKit.draw_box(self, Rect2(-width * 0.2, roof_y - 12.0, width * 0.4, 10.0), Palette.WOOD_DARK, 3)
	DrawKit.draw_text_centered(self, Vector2(0, roof_y - 7.0), "BALAI DESA", 9, Palette.GOLD_PALE)
	# bendera kecil
	DrawKit.draw_ellipse(self, Vector2(-width * 0.5, roof_y - 6.0), Vector2(7, 5), Palette.FABRIC_RED)
	DrawKit.draw_ellipse(self, Vector2(width * 0.5, roof_y - 6.0), Vector2(7, 5), Palette.FABRIC_YELLOW)


func _draw_workshop(dims: Vector2, palette: Color) -> void:
	var width := dims.x
	var height := dims.y
	var floor_h := height * 0.16
	var post_h := height * 0.62
	var roof := Palette.WOOD_DARK * palette
	DrawKit.draw_shadow(self, Vector2(0, 0), Vector2(width * 0.5, height * 0.09), 0.22)
	# lantai kerja
	DrawKit.draw_box(self, Rect2(-width * 0.48, -floor_h, width * 0.96, floor_h), Palette.SOIL, 4)
	DrawKit.draw_box(self, Rect2(-width * 0.48, -floor_h, width * 0.96, 4.0), Palette.WOOD_DARK, 2)
	# dinding belakang setengah terbuka
	DrawKit.draw_box(
		self, Rect2(-width * 0.4, -floor_h - post_h, width * 0.8, post_h * 0.55), Palette.WOOD * palette, 4
	)
	# tiang penyangga
	for side in [-1.0, 1.0]:
		DrawKit.draw_pillar(self, Vector2(side * width * 0.44, -floor_h), 9.0, post_h, Palette.WOOD, Palette.WOOD_LIGHT)
	# atap miring
	var roof_y := -floor_h - post_h
	DrawKit.draw_poly(
		self,
		PackedVector2Array(
			[
				Vector2(-width * 0.54, roof_y + 8.0),
				Vector2(width * 0.54, roof_y),
				Vector2(width * 0.44, roof_y - height * 0.22),
				Vector2(-width * 0.44, roof_y - height * 0.16),
			]
		),
		roof
	)
	for i in 4:
		DrawKit.draw_box(
			self,
			Rect2(-width * 0.46 + float(i) * width * 0.24, roof_y - height * 0.2, 5.0, height * 0.22),
			Palette.WOOD,
			1
		)
	# meja kerja + alat
	DrawKit.draw_box(self, Rect2(-width * 0.3, -floor_h - 26.0, width * 0.34, 8.0), Palette.WOOD_LIGHT, 2)
	DrawKit.draw_box(self, Rect2(-width * 0.28, -floor_h - 18.0, 6.0, 18.0), Palette.WOOD_DARK, 1)
	DrawKit.draw_box(self, Rect2(width * 0.02, -floor_h - 18.0, 6.0, 18.0), Palette.WOOD_DARK, 1)
	DrawKit.draw_box(self, Rect2(-width * 0.26, -floor_h - 32.0, 16.0, 6.0), Palette.STONE, 2)
	DrawKit.draw_box(self, Rect2(-width * 0.6 * -1.0 - 8.0, -floor_h - 30.0, 5.0, 30.0), Palette.STONE_DARK, 1)
	# rak kayu di sisi kanan
	DrawKit.draw_box(self, Rect2(width * 0.16, -floor_h - 40.0, width * 0.26, 5.0), Palette.WOOD_LIGHT, 2)
	DrawKit.draw_box(self, Rect2(width * 0.16, -floor_h - 24.0, width * 0.26, 5.0), Palette.WOOD_LIGHT, 2)
	DrawKit.draw_box(self, Rect2(width * 0.18, -floor_h - 36.0, 18.0, 30.0), Palette.WOOD, 2)
	DrawKit.draw_box(self, Rect2(width * 0.32, -floor_h - 34.0, 12.0, 28.0), Palette.BAMBOO, 2)


func _draw_saung(dims: Vector2, palette: Color) -> void:
	var width := dims.x
	var height := dims.y
	var post_h := height * 0.5
	DrawKit.draw_shadow(self, Vector2(0, 0), Vector2(width * 0.34, height * 0.06), 0.2)
	for side in [-1.0, 1.0]:
		DrawKit.draw_pillar(self, Vector2(side * width * 0.32, 0), 8.0, post_h, Palette.WOOD, Palette.WOOD_LIGHT)
	DrawKit.draw_box(self, Rect2(-width * 0.36, -post_h - 6.0, width * 0.72, 6.0), Palette.WOOD_LIGHT, 2)
	DrawKit.draw_poly(
		self,
		PackedVector2Array(
			[
				Vector2(-width * 0.52, -post_h - 6.0),
				Vector2(width * 0.52, -post_h - 6.0),
				Vector2(0, -height),
			]
		),
		Palette.PATH_SAND_DARK * palette
	)
	DrawKit.draw_line_soft(
		self, Vector2(-width * 0.5, -post_h - 8.0), Vector2(width * 0.5, -post_h - 8.0), Palette.WOOD_DARK, 2.0
	)
	# tempat duduk
	DrawKit.draw_box(self, Rect2(-width * 0.24, -12.0, width * 0.48, 6.0), Palette.WOOD, 2)
	# keranjang padi di dalam saung
	DrawKit.draw_box(self, Rect2(width * 0.1, -22.0, 14.0, 12.0), Palette.RICE_GOLD, 3)


func _draw_stage(dims: Vector2, palette: Color) -> void:
	var width := dims.x
	var height := dims.y
	var deck_h := height * 0.34
	DrawKit.draw_shadow(self, Vector2(0, 0), Vector2(width * 0.5, height * 0.1), 0.24)
	# lantai panggung
	DrawKit.draw_box(self, Rect2(-width * 0.46, -deck_h, width * 0.92, deck_h), Palette.WOOD_LIGHT, 4)
	for i in 7:
		DrawKit.draw_line_soft(
			self,
			Vector2(-width * 0.46 + float(i) * width * 0.13, -deck_h),
			Vector2(-width * 0.46 + float(i) * width * 0.13, 0),
			Palette.WOOD,
			1.0
		)
	DrawKit.draw_box(self, Rect2(-width * 0.46, -deck_h, width * 0.92, 5.0), Palette.WOOD_DARK, 2)
	# tangga
	DrawKit.draw_box(self, Rect2(-14.0, -deck_h * 0.5, 28.0, deck_h * 0.5), Palette.WOOD, 2)
	# latar belakang dengan kain pola
	var backdrop := Rect2(-width * 0.34, -deck_h - height * 0.6, width * 0.68, height * 0.6)
	DrawKit.draw_box(self, backdrop, Palette.INDIGO * palette, 6)
	for row in 2:
		for column in 5:
			var center := Vector2(
				backdrop.position.x + 24.0 + float(column) * (backdrop.size.x - 48.0) / 4.0,
				backdrop.position.y + 22.0 + float(row) * 34.0
			)
			DrawKit.draw_ellipse_ring(self, center, Vector2(9, 9), Palette.GOLD_PALE, 1.6, 14)
			DrawKit.draw_ellipse(self, center, Vector2(2.6, 2.6), Palette.GOLD_PALE)
	# tiang latar
	for side in [-1.0, 1.0]:
		DrawKit.draw_pillar(
			self, Vector2(side * width * 0.36, -deck_h), 8.0, height * 0.62, Palette.BAMBOO_DARK, Palette.BAMBOO
		)
	# umbul-umbul
	for side in [-1.0, 1.0]:
		DrawKit.draw_box(
			self, Rect2(side * width * 0.42, -deck_h - 44.0, 10.0, 34.0), Palette.FABRIC_RED if side < 0.0 else Palette.FABRIC_YELLOW, 3
		)


func _draw_gapura(dims: Vector2, palette: Color) -> void:
	var width := dims.x
	var height := dims.y
	DrawKit.draw_shadow(self, Vector2(0, 0), Vector2(width * 0.42, height * 0.06), 0.2)
	for side in [-1.0, 1.0]:
		DrawKit.draw_pillar(self, Vector2(side * width * 0.34, 0), 13.0, height * 0.78, Palette.BAMBOO_DARK, Palette.BAMBOO)
		for seg in 3:
			DrawKit.draw_box(
				self,
				Rect2(side * width * 0.34 - 6.5, -height * 0.2 - float(seg) * height * 0.2, 13.0, 3.0),
				Palette.BAMBOO,
				1
			)
	# balok atas
	DrawKit.draw_box(self, Rect2(-width * 0.44, -height * 0.9, width * 0.88, 12.0), Palette.WOOD_DARK, 3)
	DrawKit.draw_box(self, Rect2(-width * 0.36, -height * 1.0, width * 0.72, 10.0), Palette.WOOD, 3)
	# papan nama
	DrawKit.draw_box(self, Rect2(-width * 0.24, -height * 0.84, width * 0.48, 16.0), Palette.PATH_SAND, 3)
	DrawKit.draw_text_centered(self, Vector2(0, -height * 0.84 + 8.0), "ARUNIKA", 10, Palette.INK_SOFT)
	# hiasan daun
	for side in [-1.0, 1.0]:
		DrawKit.draw_ellipse(self, Vector2(side * width * 0.4, -height * 0.86), Vector2(14, 8), Palette.LEAF)
		DrawKit.draw_ellipse(self, Vector2(side * width * 0.48, -height * 0.8), Vector2(11, 6), Palette.LEAF_DARK)


# --- Pohon & tanaman -----------------------------------------------------

func _draw_tree(dims: Vector2, palette: Color, bob: float) -> void:
	var height := dims.y
	var trunk_h := height * 0.42
	DrawKit.draw_shadow(self, Vector2(0, 0), Vector2(dims.x * 0.34, dims.y * 0.07), 0.22)
	DrawKit.draw_pillar(self, Vector2(0, 0), 16.0, trunk_h, Palette.WOOD_DARK, Palette.WOOD)
	var canopy_center := Vector2(0, -trunk_h - height * 0.26 + bob)
	var radius := dims.x * 0.44
	DrawKit.draw_ellipse(self, canopy_center + Vector2(0, radius * 0.42), Vector2(radius * 1.05, radius * 0.7), Palette.LEAF_DARK)
	DrawKit.draw_ellipse(self, canopy_center, Vector2(radius, radius * 0.82), Palette.LEAF)
	DrawKit.draw_ellipse(self, canopy_center + Vector2(-radius * 0.34, -radius * 0.3), Vector2(radius * 0.5, radius * 0.4), Palette.LEAF_LIGHT)
	DrawKit.draw_ellipse(self, canopy_center + Vector2(radius * 0.42, radius * 0.1), Vector2(radius * 0.4, radius * 0.34), Palette.GRASS_DARK)


func _draw_palm(dims: Vector2, palette: Color, bob: float) -> void:
	var height := dims.y
	DrawKit.draw_shadow(self, Vector2(0, 0), Vector2(dims.x * 0.24, dims.y * 0.05), 0.2)
	# batang melengkung
	var trunk: PackedVector2Array = PackedVector2Array()
	for i in 6:
		var t := float(i) / 5.0
		trunk.append(Vector2(sin(t * 0.6) * 8.0, -height * 0.72 * t))
	trunk.append(Vector2(sin(0.6) * 8.0, -height * 0.72))
	for i in trunk.size() - 1:
		DrawKit.draw_line_soft(self, trunk[i], trunk[i + 1], Palette.WOOD_DARK, 9.0)
		DrawKit.draw_line_soft(self, trunk[i], trunk[i + 1], Palette.WOOD, 6.0)
	var top := trunk[trunk.size() - 1] + Vector2(0, bob)
	for i in 7:
		var angle := -PI * 0.95 + float(i) * (PI * 0.9 / 6.0)
		var tip := top + Vector2(cos(angle), sin(angle)) * dims.x * 0.46
		DrawKit.draw_line_soft(self, top, tip, Palette.LEAF_DARK, 6.0)
		DrawKit.draw_line_soft(self, top + Vector2(0, 1.0), tip, Palette.LEAF, 3.4)
	DrawKit.draw_ellipse(self, top, Vector2(6, 5), Palette.LEAF_DARK)


func _draw_bamboo_clump(dims: Vector2, palette: Color, bob: float) -> void:
	var height := dims.y
	DrawKit.draw_shadow(self, Vector2(0, 0), Vector2(dims.x * 0.36, dims.y * 0.06), 0.22)
	for i in 4:
		var x := lerpf(-dims.x * 0.28, dims.x * 0.28, float(i) / 3.0)
		var stalk_h := height * (0.72 + 0.08 * float(i % 2))
		var lean := sin(float(i) * 1.7 + _time * 0.6) * 2.5 if sway else 0.0
		DrawKit.draw_pillar(self, Vector2(x, 0), 7.0, stalk_h, Palette.BAMBOO_DARK, Palette.BAMBOO)
		for seg in 4:
			DrawKit.draw_box(
				self, Rect2(x - 3.6, -stalk_h * 0.25 * float(seg + 1), 7.2, 2.0), Palette.BAMBOO, 0
			)
		var top := Vector2(x + lean, -stalk_h + bob * 0.4)
		for j in 4:
			var side := -1.0 if j % 2 == 0 else 1.0
			DrawKit.draw_ellipse(
				self, top + Vector2(side * 9.0, -float(j) * 7.0), Vector2(11.0, 4.0), Palette.LEAF if j % 2 == 0 else Palette.LEAF_LIGHT
			)


func _draw_flower_bush(dims: Vector2, palette: Color, bob: float) -> void:
	var radius := dims.x * 0.5
	DrawKit.draw_shadow(self, Vector2(0, 0), Vector2(radius * 0.8, dims.y * 0.14), 0.18)
	DrawKit.draw_ellipse(self, Vector2(0, -dims.y * 0.4 + bob * 0.5), Vector2(radius, dims.y * 0.42), Palette.LEAF_DARK)
	DrawKit.draw_ellipse(self, Vector2(-radius * 0.2, -dims.y * 0.5 + bob * 0.5), Vector2(radius * 0.7, dims.y * 0.32), Palette.LEAF)
	for i in 4:
		var x := lerpf(-radius * 0.6, radius * 0.6, float(i) / 3.0)
		DrawKit.draw_ellipse(
			self, Vector2(x, -dims.y * (0.5 + 0.12 * float(i % 2)) + bob * 0.5), Vector2(4.2, 4.2), Palette.ROSE if i % 2 == 0 else Palette.GOLD
		)


func _draw_grass_tuft(dims: Vector2, palette: Color, bob: float) -> void:
	for i in 5:
		var x := lerpf(-dims.x * 0.4, dims.x * 0.4, float(i) / 4.0)
		var tip := Vector2(x + sin(_time * 1.4 + float(i)) * 1.6 + bob * 0.2, -dims.y * (0.7 + 0.3 * float(i % 2)))
		DrawKit.draw_line_soft(self, Vector2(x, 0), tip, Palette.GRASS_DARK, 2.6)
		DrawKit.draw_line_soft(self, Vector2(x, 0), tip * 0.8, Palette.LEAF_LIGHT, 1.4)


func _draw_rice_sheaf(dims: Vector2, palette: Color) -> void:
	for i in 6:
		var x := lerpf(-dims.x * 0.35, dims.x * 0.35, float(i) / 5.0)
		DrawKit.draw_line_soft(self, Vector2(x * 0.4, 0), Vector2(x, -dims.y * 0.85), Palette.RICE_GOLD, 3.0)
		DrawKit.draw_ellipse(self, Vector2(x, -dims.y * 0.85), Vector2(3.4, 5.0), Palette.RICE_GREEN)
	DrawKit.draw_box(self, Rect2(-dims.x * 0.3, -dims.y * 0.45, dims.x * 0.6, 4.0), Palette.WOOD_DARK, 2)


func _draw_scarecrow(dims: Vector2, palette: Color, bob: float) -> void:
	var height := dims.y
	DrawKit.draw_shadow(self, Vector2(0, 0), Vector2(10, 4), 0.2)
	DrawKit.draw_pillar(self, Vector2(0, 0), 6.0, height, Palette.BAMBOO_DARK)
	DrawKit.draw_box(self, Rect2(-dims.x * 0.42, -height * 0.72, dims.x * 0.84, 5.0), Palette.WOOD, 2)
	DrawKit.draw_box(self, Rect2(-9.0, -height * 0.7, 18.0, height * 0.24), Palette.FABRIC_YELLOW, 4)
	var head := Vector2(0, -height * 0.78 + bob * 0.5)
	DrawKit.draw_ellipse(self, head, Vector2(9, 9), Palette.PATH_SAND)
	DrawKit.draw_ellipse(self, head + Vector2(0, -3.6), Vector2(12, 7), Palette.PATH_SAND_DARK)
	DrawKit.draw_ellipse(self, head + Vector2(-3, 0), Vector2(1.5, 1.5), Palette.INK)
	DrawKit.draw_ellipse(self, head + Vector2(3, 0), Vector2(1.5, 1.5), Palette.INK)


func _draw_lily(dims: Vector2, palette: Color) -> void:
	DrawKit.draw_ellipse(self, Vector2(0, -2), Vector2(dims.x * 0.5, dims.y * 0.34), Palette.LEAF)
	DrawKit.draw_ellipse(self, Vector2(0, -2), Vector2(dims.x * 0.5, dims.y * 0.34), Palette.with_alpha(Palette.LEAF_DARK, 0.35))
	DrawKit.draw_ellipse(self, Vector2(dims.x * 0.12, -3.5), Vector2(4.0, 2.6), Palette.ROSE)


func _draw_rock(dims: Vector2, palette: Color) -> void:
	DrawKit.draw_shadow(self, Vector2(0, 0), Vector2(dims.x * 0.42, dims.y * 0.2), 0.2)
	DrawKit.draw_poly(
		self,
		PackedVector2Array(
			[
				Vector2(-dims.x * 0.46, 0),
				Vector2(-dims.x * 0.34, -dims.y * 0.72),
				Vector2(0, -dims.y),
				Vector2(dims.x * 0.36, -dims.y * 0.66),
				Vector2(dims.x * 0.46, 0),
			]
		),
		Palette.STONE * palette
	)
	DrawKit.draw_poly(
		self,
		PackedVector2Array(
			[
				Vector2(-dims.x * 0.34, -dims.y * 0.72),
				Vector2(0, -dims.y),
				Vector2(0, -dims.y * 0.4),
			]
		),
		Palette.STONE_DARK * palette
	)


# --- Perabot & alat ------------------------------------------------------

func _draw_bench(dims: Vector2, palette: Color) -> void:
	DrawKit.draw_shadow(self, Vector2(0, 0), Vector2(dims.x * 0.5, dims.y * 0.22), 0.2)
	DrawKit.draw_box(self, Rect2(-dims.x * 0.48, -dims.y * 0.56, dims.x * 0.96, 7.0), Palette.WOOD_LIGHT, 2)
	DrawKit.draw_box(self, Rect2(-dims.x * 0.46, -dims.y * 0.98, dims.x * 0.92, 6.0), Palette.WOOD, 2)
	for side in [-1.0, 1.0]:
		DrawKit.draw_box(self, Rect2(side * dims.x * 0.4 - 3.0, -dims.y * 0.56, 6.0, dims.y * 0.56), Palette.WOOD_DARK, 2)


func _draw_table(dims: Vector2, palette: Color) -> void:
	DrawKit.draw_shadow(self, Vector2(0, 0), Vector2(dims.x * 0.5, dims.y * 0.2), 0.2)
	DrawKit.draw_box(self, Rect2(-dims.x * 0.5, -dims.y * 0.7, dims.x, 8.0), Palette.WOOD_LIGHT, 3)
	for side in [-1.0, 1.0]:
		DrawKit.draw_box(self, Rect2(side * dims.x * 0.4 - 3.0, -dims.y * 0.7, 6.0, dims.y * 0.7), Palette.WOOD_DARK, 2)


func _draw_lamp(dims: Vector2, palette: Color) -> void:
	DrawKit.draw_shadow(self, Vector2(0, 0), Vector2(9, 4), 0.22)
	DrawKit.draw_pillar(self, Vector2(0, 0), 7.0, dims.y * 0.82, Palette.WOOD_DARK, Palette.WOOD)
	var lamp_center := Vector2(0, -dims.y * 0.9)
	if glow > 0.01:
		draw_texture(
			TextureFactory.soft_dot(96, 0.05, Palette.LANTERN),
			lamp_center - Vector2(48, 48),
			Palette.with_alpha(Palette.LANTERN, 0.55 * glow)
		)
	DrawKit.draw_box(self, Rect2(-9.0, -dims.y * 0.9, 18.0, 16.0), Palette.LANTERN, 5)
	DrawKit.draw_box(self, Rect2(-11.0, -dims.y * 0.94, 22.0, 4.0), Palette.WOOD_DARK, 2)
	DrawKit.draw_box(self, Rect2(-6.0, -dims.y * 0.78, 12.0, 3.0), Palette.FIRE, 1)


func _draw_crate(dims: Vector2, palette: Color) -> void:
	DrawKit.draw_shadow(self, Vector2(0, 0), Vector2(dims.x * 0.5, dims.y * 0.2), 0.2)
	DrawKit.draw_box(self, Rect2(-dims.x * 0.5, -dims.y * 0.9, dims.x, dims.y * 0.9), Palette.WOOD_LIGHT, 4)
	DrawKit.draw_box(self, Rect2(-dims.x * 0.5, -dims.y * 0.9, dims.x, 5.0), Palette.WOOD_DARK, 2)
	DrawKit.draw_line_soft(
		self, Vector2(-dims.x * 0.5, -dims.y * 0.9), Vector2(dims.x * 0.5, -2.0), Palette.WOOD_DARK, 2.0
	)
	DrawKit.draw_line_soft(
		self, Vector2(dims.x * 0.5, -dims.y * 0.9), Vector2(-dims.x * 0.5, -2.0), Palette.WOOD_DARK, 2.0
	)


func _draw_wood_stack(dims: Vector2, palette: Color) -> void:
	DrawKit.draw_shadow(self, Vector2(0, 0), Vector2(dims.x * 0.5, dims.y * 0.2), 0.2)
	for row in 3:
		var count := 3 - row
		for i in count:
			var x := lerpf(-dims.x * 0.4, dims.x * 0.4, float(i) / maxf(float(count - 1), 1.0))
			DrawKit.draw_box(
				self,
				Rect2(x - dims.x * 0.22, -dims.y * 0.32 * float(row + 1), dims.x * 0.44, dims.y * 0.28),
				Palette.WOOD_LIGHT if row % 2 == 0 else Palette.WOOD,
				3
			)


func _draw_tools(dims: Vector2, palette: Color) -> void:
	DrawKit.draw_shadow(self, Vector2(0, 0), Vector2(dims.x * 0.5, dims.y * 0.2), 0.16)
	# gergaji
	DrawKit.draw_box(self, Rect2(-dims.x * 0.45, -8.0, dims.x * 0.5, 4.0), Palette.STONE, 1)
	DrawKit.draw_box(self, Rect2(dims.x * 0.02, -9.0, 8.0, 6.0), Palette.WOOD_DARK, 2)
	# ketam
	DrawKit.draw_box(self, Rect2(-dims.x * 0.1, -6.0, 16.0, 6.0), Palette.WOOD, 2)
	DrawKit.draw_box(self, Rect2(-dims.x * 0.02, -8.0, 4.0, 2.0), Palette.STONE_DARK, 1)


func _draw_cart(dims: Vector2, palette: Color) -> void:
	DrawKit.draw_shadow(self, Vector2(0, 0), Vector2(dims.x * 0.5, dims.y * 0.2), 0.2)
	DrawKit.draw_box(self, Rect2(-dims.x * 0.5, -dims.y * 0.7, dims.x, dims.y * 0.4), Palette.WOOD_LIGHT, 4)
	DrawKit.draw_box(self, Rect2(-dims.x * 0.5, -dims.y * 0.7, dims.x, 5.0), Palette.WOOD_DARK, 2)
	for side in [-1.0, 1.0]:
		DrawKit.draw_ellipse(self, Vector2(side * dims.x * 0.32, -dims.y * 0.16), Vector2(13, 13), Palette.WOOD_DARK)
		DrawKit.draw_ellipse(self, Vector2(side * dims.x * 0.32, -dims.y * 0.16), Vector2(6, 6), Palette.WOOD)
	DrawKit.draw_line_soft(
		self, Vector2(-dims.x * 0.5, -dims.y * 0.6), Vector2(-dims.x * 0.62, -dims.y * 0.5), Palette.WOOD_DARK, 4.0
	)


func _draw_basket(dims: Vector2, palette: Color) -> void:
	DrawKit.draw_shadow(self, Vector2(0, 0), Vector2(dims.x * 0.42, dims.y * 0.18), 0.18)
	DrawKit.draw_poly(
		self,
		PackedVector2Array(
			[
				Vector2(-dims.x * 0.5, -2.0),
				Vector2(dims.x * 0.5, -2.0),
				Vector2(dims.x * 0.34, -dims.y * 0.7),
				Vector2(-dims.x * 0.34, -dims.y * 0.7),
			]
		),
		Palette.PATH_SAND_DARK
	)
	for i in 3:
		DrawKit.draw_line_soft(
			self,
			Vector2(-dims.x * 0.5 + float(i) * dims.x * 0.3, -2.0),
			Vector2(-dims.x * 0.34 + float(i) * dims.x * 0.24, -dims.y * 0.7),
			Palette.PATH_SAND,
			1.4
		)
	DrawKit.draw_ellipse_ring(self, Vector2(0, -dims.y * 0.7), Vector2(dims.x * 0.3, dims.y * 0.42), Palette.PATH_SAND, 2.0, 16)


func _draw_barrel(dims: Vector2, palette: Color) -> void:
	DrawKit.draw_shadow(self, Vector2(0, 0), Vector2(dims.x * 0.46, dims.y * 0.16), 0.2)
	DrawKit.draw_box(self, Rect2(-dims.x * 0.46, -dims.y * 0.86, dims.x * 0.92, dims.y * 0.86), Palette.WOOD, 6)
	DrawKit.draw_box(self, Rect2(-dims.x * 0.48, -dims.y * 0.7, dims.x * 0.96, 5.0), Palette.STONE_DARK, 2)
	DrawKit.draw_box(self, Rect2(-dims.x * 0.48, -dims.y * 0.3, dims.x * 0.96, 5.0), Palette.STONE_DARK, 2)
	DrawKit.draw_ellipse(self, Vector2(0, -dims.y * 0.86), Vector2(dims.x * 0.46, dims.y * 0.12), Palette.WATER)


func _draw_well(dims: Vector2, palette: Color) -> void:
	DrawKit.draw_shadow(self, Vector2(0, 0), Vector2(dims.x * 0.46, dims.y * 0.16), 0.2)
	DrawKit.draw_box(self, Rect2(-dims.x * 0.42, -dims.y * 0.34, dims.x * 0.84, dims.y * 0.34), Palette.STONE, 6)
	for i in 4:
		var x := lerpf(-dims.x * 0.34, dims.x * 0.34, float(i) / 3.0)
		DrawKit.draw_box(self, Rect2(x - 5.0, -dims.y * 0.4, 10.0, 8.0), Palette.STONE_DARK, 2)
	DrawKit.draw_ellipse(self, Vector2(0, -dims.y * 0.34), Vector2(dims.x * 0.42, dims.y * 0.12), Palette.WATER_DEEP)
	for side in [-1.0, 1.0]:
		DrawKit.draw_pillar(self, Vector2(side * dims.x * 0.3, -dims.y * 0.34), 5.0, dims.y * 0.42, Palette.WOOD, Palette.WOOD_LIGHT)
	DrawKit.draw_box(self, Rect2(-dims.x * 0.48, -dims.y * 0.86, dims.x * 0.96, 6.0), Palette.WOOD_DARK, 2)
	DrawKit.draw_box(self, Rect2(-dims.x * 0.3, -dims.y * 0.72, 8.0, 6.0), Palette.WOOD, 2)
	DrawKit.draw_line_soft(
		self, Vector2(0, -dims.y * 0.72), Vector2(0, -dims.y * 0.42), Palette.CREAM_DARK, 1.6
	)


func _draw_fence(dims: Vector2, palette: Color) -> void:
	DrawKit.draw_shadow(self, Vector2(0, 0), Vector2(dims.x * 0.5, dims.y * 0.16), 0.18)
	var posts := 4
	for i in posts:
		var x := lerpf(-dims.x * 0.46, dims.x * 0.46, float(i) / float(posts - 1))
		DrawKit.draw_box(self, Rect2(x - 3.5, -dims.y * 0.9, 7.0, dims.y * 0.9), Palette.WOOD_DARK, 3)
	for row in 2:
		DrawKit.draw_box(
			self,
			Rect2(-dims.x * 0.5, -dims.y * (0.9 - 0.3 * float(row)), dims.x, 5.0),
			Palette.WOOD_LIGHT if row == 0 else Palette.WOOD,
			2
		)


func _draw_banner(dims: Vector2, palette: Color, bob: float) -> void:
	DrawKit.draw_shadow(self, Vector2(0, 0), Vector2(8, 4), 0.2)
	DrawKit.draw_pillar(self, Vector2(0, 0), 5.0, dims.y, Palette.WOOD_DARK, Palette.WOOD)
	var cloth := Rect2(2.0 + bob * 0.4, -dims.y * 0.94, 12.0, 30.0)
	DrawKit.draw_box(self, cloth, Palette.FABRIC_RED if variant % 2 == 0 else Palette.FABRIC_YELLOW, 2)
	DrawKit.draw_box(self, Rect2(cloth.position.x, cloth.position.y, 12.0, 4.0), Palette.CREAM, 1)


func _draw_fire_pit(dims: Vector2, palette: Color) -> void:
	for i in 7:
		var angle := TAU * float(i) / 7.0
		DrawKit.draw_ellipse(
			self, Vector2(cos(angle) * dims.x * 0.4, sin(angle) * dims.y * 0.34), Vector2(7, 5), Palette.STONE
		)
	DrawKit.draw_ellipse(self, Vector2(0, 0), Vector2(dims.x * 0.3, dims.y * 0.24), Palette.INK_SOFT)
	var flame_h := dims.y * (1.6 + 0.2 * sin(_time * 6.0))
	var flame := PackedVector2Array(
		[
			Vector2(-10.0, 0),
			Vector2(0, -flame_h),
			Vector2(10.0, 0),
		]
	)
	DrawKit.draw_poly(self, flame, Palette.FIRE)
	DrawKit.draw_poly(
		self,
		PackedVector2Array([Vector2(-5.0, -2.0), Vector2(0, -flame_h * 0.6), Vector2(5.0, -2.0)]),
		Palette.GOLD_PALE
	)
	draw_texture(
		TextureFactory.soft_dot(72, 0.05, Palette.FIRE),
		Vector2(-36, -flame_h * 0.8 - 36.0),
		Palette.with_alpha(Palette.FIRE, 0.35)
	)


func _draw_sign_post(dims: Vector2, palette: Color) -> void:
	DrawKit.draw_shadow(self, Vector2(0, 0), Vector2(9, 4), 0.2)
	DrawKit.draw_pillar(self, Vector2(0, 0), 6.0, dims.y, Palette.WOOD_DARK, Palette.WOOD)
	DrawKit.draw_box(self, Rect2(-dims.x * 0.5, -dims.y * 0.96, dims.x, 20.0), Palette.PATH_SAND, 3)
	DrawKit.draw_box(self, Rect2(-dims.x * 0.44, -dims.y * 0.9, dims.x * 0.88, 13.0), Palette.PATH_SAND_DARK, 2)
	DrawKit.draw_line_soft(
		self, Vector2(-dims.x * 0.34, -dims.y * 0.84), Vector2(dims.x * 0.34, -dims.y * 0.84), Palette.INK_SOFT, 1.6
	)
