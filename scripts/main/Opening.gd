extends Node2D
## Layar pembuka: Raka turun dari bus di ujung jalan desa.
##
## Narasi dibacakan lewat kotak dialog (data "opening_narasi"). Setelah selesai
## — atau saat pemain menekan ESC/SPACE — pemain masuk ke Desa Arunika.

const RAKA_POSITION := Vector2(560.0, 606.0)

var _time := 0.0
var _started := false
var _leaving := false

var _raka: CharacterVisual


func _ready() -> void:
	GameManager.audio.play_music("menu", 0.9)
	_raka = CharacterVisual.new()
	_raka.palette_id = "raka"
	_raka.facing = Vector2.UP
	_raka.position = RAKA_POSITION
	add_child(_raka)
	set_process(true)


func _process(delta: float) -> void:
	_time += delta
	if _raka != null:
		_raka.facing = Vector2.UP
		_raka.speed_ratio = 0.45
	queue_redraw()


func notify_screen_ready() -> void:
	if _started:
		return
	_started = true
	DialogueManager.dialogue_finished.connect(_on_dialogue_finished)
	DialogueManager.start("opening_narasi")


func _on_dialogue_finished(dialogue_id: String) -> void:
	if dialogue_id == "opening_narasi":
		_leave()


func _unhandled_input(event: InputEvent) -> void:
	if _leaving or DialogueManager.is_active:
		return
	if (
		event.is_action_pressed("pause")
		or event.is_action_pressed("interact")
		or event.is_action_pressed("ui_accept")
	):
		_leave()


func _leave() -> void:
	if _leaving:
		return
	_leaving = true
	DialogueManager.abort()
	GameManager.goto_screen("village")


# --- Gambar ---------------------------------------------------------------

func _draw() -> void:
	var screen := get_viewport_rect().size
	_draw_sky(screen)
	_draw_hills(screen)
	_draw_field(screen)
	_draw_road(screen)
	_draw_gate(screen)
	_draw_hint(screen)


func _draw_sky(screen: Vector2) -> void:
	var bands := [
		[Palette.DUSK_HIGH, 0.0, 0.3],
		[Palette.mix(Palette.DUSK_HIGH, Palette.DUSK_SKY, 0.6), 0.3, 0.22],
		[Palette.DUSK_SKY, 0.52, 0.18],
		[Palette.SKY_WARM, 0.66, 0.14],
	]
	for band in bands:
		var color: Color = band[0]
		draw_rect(Rect2(0, screen.y * float(band[1]), screen.x, screen.y * float(band[2]) + 1.0), color)
	var sun := Vector2(screen.x * 0.78, screen.y * 0.7 - 30.0)
	DrawKit.draw_ellipse(self, sun, Vector2(210, 210), Palette.with_alpha(Palette.GOLD_PALE, 0.1))
	DrawKit.draw_ellipse(self, sun, Vector2(120, 120), Palette.with_alpha(Palette.GOLD_PALE, 0.18))
	DrawKit.draw_ellipse(self, sun, Vector2(62, 62), Palette.with_alpha(Palette.LANTERN, 0.9))


func _draw_hills(screen: Vector2) -> void:
	var horizon := screen.y * 0.7
	DrawKit.draw_ellipse(
		self, Vector2(screen.x * 0.22, horizon + 30.0), Vector2(560, 190), Palette.with_alpha(Palette.LEAF_DARK, 0.45)
	)
	DrawKit.draw_ellipse(
		self, Vector2(screen.x * 0.8, horizon + 10.0), Vector2(520, 170), Palette.with_alpha(Palette.GRASS_DARK, 0.6)
	)


func _draw_field(screen: Vector2) -> void:
	var horizon := screen.y * 0.7
	draw_rect(Rect2(0, horizon, screen.x, screen.y - horizon), Palette.GRASS_DARK)
	var index := 0
	while index < 6:
		var y := horizon + 22.0 + float(index) * 26.0
		if y > screen.y:
			break
		DrawKit.draw_line_soft(self, Vector2(0, y), Vector2(screen.x, y), Palette.with_alpha(Palette.RICE_GREEN, 0.35), 3.0)
		index += 1
	_draw_house(Vector2(screen.x * 0.24, horizon + 18.0), 0.7)
	_draw_house(Vector2(screen.x * 0.36, horizon + 30.0), 0.55)
	DrawKit.draw_pillar(self, Vector2(screen.x * 0.9, horizon + 46.0), 11.0, 76.0, Palette.WOOD, Palette.WOOD_DARK)
	DrawKit.draw_ellipse(self, Vector2(screen.x * 0.9, horizon - 14.0), Vector2(66, 48), Palette.LEAF_DARK)
	DrawKit.draw_ellipse(self, Vector2(screen.x * 0.9 - 30.0, horizon + 4.0), Vector2(42, 30), Palette.LEAF)


func _draw_house(base: Vector2, scale: float) -> void:
	var width := 150.0 * scale
	var wall := 74.0 * scale
	var body := Rect2(base.x - width * 0.5, base.y - wall, width, wall)
	DrawKit.draw_box(self, body, Palette.WOOD_DARK, 3)
	DrawKit.draw_poly(
		self,
		PackedVector2Array(
			[
				Vector2(body.position.x - 14.0 * scale, body.position.y),
				Vector2(base.x, body.position.y - 48.0 * scale),
				Vector2(body.end.x + 14.0 * scale, body.position.y),
			]
		),
		Palette.ROOF_TILE
	)
	DrawKit.draw_box(
		self,
		Rect2(base.x - 12.0 * scale, base.y - 44.0 * scale, 24.0 * scale, 20.0 * scale),
		Palette.with_alpha(Palette.LANTERN, 0.55),
		2
	)


func _draw_road(screen: Vector2) -> void:
	DrawKit.draw_band(
		self,
		Vector2(screen.x * 0.42, screen.y * 0.68),
		Vector2(screen.x * 0.5, screen.y),
		150.0,
		Palette.with_alpha(Palette.PATH_SAND, 0.85)
	)
	DrawKit.draw_band(
		self,
		Vector2(screen.x * 0.44, screen.y * 0.7),
		Vector2(screen.x * 0.5, screen.y),
		24.0,
		Palette.with_alpha(Palette.PATH_SAND_DARK, 0.5)
	)


func _draw_gate(screen: Vector2) -> void:
	var left := Vector2(screen.x * 0.44, screen.y * 0.66)
	var right := Vector2(screen.x * 0.56, screen.y * 0.66)
	var height := 168.0
	DrawKit.draw_pillar(self, left, 14.0, height, Palette.WOOD, Palette.WOOD_DARK)
	DrawKit.draw_pillar(self, right, 14.0, height, Palette.WOOD, Palette.WOOD_DARK)
	DrawKit.draw_box(
		self, Rect2(left.x - 16.0, left.y - height - 26.0, right.x - left.x + 32.0, 30.0), Palette.ROOF_TILE, 6
	)
	DrawKit.draw_box(
		self, Rect2(left.x + 6.0, left.y - height + 24.0, right.x - left.x - 12.0, 34.0), Palette.WOOD_LIGHT, 4
	)
	DrawKit.draw_text_centered(
		self, Vector2(screen.x * 0.5, left.y - height + 40.0), "DESA ARUNIKA", 15, Palette.INK
	)


func _draw_hint(screen: Vector2) -> void:
	var alpha := 0.55 + sin(_time * 2.0) * 0.2
	DrawKit.draw_text(
		self,
		Vector2(screen.x - 250.0, screen.y - 28.0),
		"ESC untuk melewati  ▸",
		16,
		Palette.with_alpha(Palette.CREAM_DIM, alpha)
	)
