extends Node2D
## Adegan penutup: warga berkumpul di Lapangan Guyub saat malam.
##
## Setelah narasi penutup selesai, judul game dan tagline muncul, lalu pemain
## dibawa ke layar kredit.

const FIRE_POSITION := Vector2(640.0, 452.0)
const TITLE_HOLD := 6.5

const VILLAGERS := [
	{"palette": "mbah_seno", "pos": Vector2(640.0, 404.0), "facing": Vector2.DOWN},
	{"palette": "sari", "pos": Vector2(524.0, 438.0), "facing": Vector2.RIGHT},
	{"palette": "dimas", "pos": Vector2(760.0, 442.0), "facing": Vector2.LEFT},
	{"palette": "bu_rini", "pos": Vector2(468.0, 486.0), "facing": Vector2.RIGHT},
	{"palette": "pak_jaya", "pos": Vector2(806.0, 490.0), "facing": Vector2.LEFT},
	{"palette": "warga_petani", "pos": Vector2(586.0, 512.0), "facing": Vector2.UP},
	{"palette": "warga_penjual", "pos": Vector2(712.0, 518.0), "facing": Vector2.UP},
	{"palette": "warga_anak", "pos": Vector2(690.0, 372.0), "facing": Vector2.DOWN},
]

@onready var villagers_root: Node2D = $Villagers
@onready var title_card: Control = $TitleCard
@onready var credits_button: Button = $TitleCard/CreditsButton

var _time := 0.0
var _stars: Array[Vector2] = []
var _started := false
var _title_shown := false
var _leaving := false


func _ready() -> void:
	GameManager.audio.play_music("ending", 1.4)
	GameManager.audio.stop_ambient(1.0)
	_build_stars()
	_build_villagers()
	credits_button.pressed.connect(_go_to_credits)
	credits_button.mouse_entered.connect(_on_button_hover)
	set_process(true)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func notify_screen_ready() -> void:
	if _started:
		return
	_started = true
	DialogueManager.dialogue_finished.connect(_on_dialogue_finished)
	DialogueManager.start("ending_narasi")


func _on_dialogue_finished(dialogue_id: String) -> void:
	if dialogue_id == "ending_narasi":
		_show_title_card()


func _unhandled_input(event: InputEvent) -> void:
	if _leaving or DialogueManager.is_active:
		return
	if (
		event.is_action_pressed("pause")
		or event.is_action_pressed("interact")
		or event.is_action_pressed("ui_accept")
	):
		if _title_shown:
			_go_to_credits()
		else:
			_show_title_card()


func _show_title_card() -> void:
	if _title_shown:
		return
	_title_shown = true
	DialogueManager.abort()
	title_card.visible = true
	title_card.modulate.a = 0.0
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(title_card, "modulate:a", 1.0, 1.3)
	GameManager.audio.play_sfx("gong", -5.0)
	await get_tree().create_timer(TITLE_HOLD).timeout
	_go_to_credits()


func _go_to_credits() -> void:
	if _leaving:
		return
	_leaving = true
	DialogueManager.abort()
	GameManager.goto_screen("credits")


func _on_button_hover() -> void:
	GameManager.audio.play_sfx("hover", -14.0)


# --- Isi adegan -----------------------------------------------------------

func _build_stars() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261115
	for i in 70:
		_stars.append(Vector2(rng.randf_range(0.0, 1280.0), rng.randf_range(0.0, 380.0)))


func _build_villagers() -> void:
	for entry in VILLAGERS:
		var visual := CharacterVisual.new()
		visual.palette_id = str(entry["palette"])
		visual.facing = entry["facing"]
		visual.position = entry["pos"]
		villagers_root.add_child(visual)


# --- Gambar ---------------------------------------------------------------

func _draw() -> void:
	var screen := get_viewport_rect().size
	_draw_night(screen)
	_draw_village(screen)
	_draw_ground(screen)
	_draw_fire()
	_draw_lanterns()
	if _title_shown:
		draw_rect(Rect2(Vector2.ZERO, screen), Palette.with_alpha(Palette.NIGHT_SKY, 0.72))


func _draw_night(screen: Vector2) -> void:
	var horizon := screen.y * 0.62
	draw_rect(Rect2(0, 0, screen.x, horizon + 2.0), Palette.NIGHT_SKY)
	draw_rect(Rect2(0, horizon - 130.0, screen.x, 132.0), Palette.with_alpha(Palette.DUSK_HIGH, 0.35))
	for index in _stars.size():
		var star: Vector2 = _stars[index]
		var twinkle := 0.4 + sin(_time * 2.0 + float(index)) * 0.3
		DrawKit.draw_ellipse(self, star, Vector2(1.8, 1.8), Palette.with_alpha(Palette.CREAM, twinkle))
	DrawKit.draw_ellipse(self, Vector2(screen.x * 0.84, 108.0), Vector2(66, 66), Palette.with_alpha(Palette.CREAM_DIM, 0.12))
	DrawKit.draw_ellipse(self, Vector2(screen.x * 0.84, 108.0), Vector2(28, 28), Palette.with_alpha(Palette.CREAM, 0.85))


func _draw_village(screen: Vector2) -> void:
	var horizon := screen.y * 0.62
	DrawKit.draw_ellipse(self, Vector2(screen.x * 0.2, horizon + 20.0), Vector2(520, 150), Palette.with_alpha(Palette.NIGHT_SKY, 0.9))
	DrawKit.draw_ellipse(self, Vector2(screen.x * 0.78, horizon + 10.0), Vector2(560, 170), Palette.with_alpha(Palette.NIGHT_SKY, 0.75))
	for i in 3:
		var base := Vector2(180.0 + float(i) * 250.0, horizon + 6.0)
		var width := 130.0
		DrawKit.draw_box(
			self, Rect2(base.x - width * 0.5, base.y - 74.0, width, 74.0), Palette.with_alpha(Palette.WOOD_DARK, 0.85), 3
		)
		DrawKit.draw_poly(
			self,
			PackedVector2Array(
				[
					Vector2(base.x - width * 0.5 - 14.0, base.y - 74.0),
					Vector2(base.x, base.y - 122.0),
					Vector2(base.x + width * 0.5 + 14.0, base.y - 74.0),
				]
			),
			Palette.with_alpha(Palette.ROOF_SHADOW, 0.9)
		)
		DrawKit.draw_box(
			self,
			Rect2(base.x - 13.0, base.y - 56.0, 26.0, 22.0),
			Palette.with_alpha(Palette.LANTERN, 0.7 + sin(_time * 1.6 + float(i)) * 0.08),
			2
		)


func _draw_ground(screen: Vector2) -> void:
	var horizon := screen.y * 0.62
	draw_rect(Rect2(0, horizon, screen.x, screen.y - horizon), Palette.with_alpha(Palette.GRASS_DARK, 0.92))
	# meja dan panggung hasil kerja warga
	DrawKit.draw_box(self, Rect2(300.0, 392.0, 220.0, 20.0), Palette.with_alpha(Palette.WOOD, 0.9), 4)
	DrawKit.draw_box(self, Rect2(316.0, 412.0, 14.0, 32.0), Palette.with_alpha(Palette.WOOD_DARK, 0.9), 3)
	DrawKit.draw_box(self, Rect2(490.0, 412.0, 14.0, 32.0), Palette.with_alpha(Palette.WOOD_DARK, 0.9), 3)
	DrawKit.draw_box(self, Rect2(806.0, 402.0, 180.0, 18.0), Palette.with_alpha(Palette.WOOD_LIGHT, 0.9), 4)
	# gapura yang sudah berdiri
	DrawKit.draw_pillar(
		self, Vector2(196.0, 470.0), 12.0, 150.0, Palette.with_alpha(Palette.WOOD, 0.95), Palette.with_alpha(Palette.WOOD_DARK, 0.95)
	)
	DrawKit.draw_pillar(
		self, Vector2(1090.0, 470.0), 12.0, 150.0, Palette.with_alpha(Palette.WOOD, 0.95), Palette.with_alpha(Palette.WOOD_DARK, 0.95)
	)
	DrawKit.draw_box(self, Rect2(180.0, 306.0, 924.0, 22.0), Palette.with_alpha(Palette.ROOF_TILE, 0.95), 6)


func _draw_fire() -> void:
	var flicker := 0.8 + sin(_time * 9.0) * 0.08 + sin(_time * 3.3) * 0.06
	DrawKit.draw_ellipse(self, FIRE_POSITION, Vector2(180, 90), Palette.with_alpha(Palette.FIRE, 0.08 * flicker))
	DrawKit.draw_ellipse(self, FIRE_POSITION, Vector2(96, 52), Palette.with_alpha(Palette.FIRE, 0.14 * flicker))
	DrawKit.draw_ellipse(
		self, FIRE_POSITION + Vector2(0, -6), Vector2(38, 26), Palette.with_alpha(Palette.LANTERN, 0.85 * flicker)
	)
	DrawKit.draw_ellipse(
		self, FIRE_POSITION + Vector2(0, -12), Vector2(20, 16), Palette.with_alpha(Palette.CREAM, 0.9 * flicker)
	)
	DrawKit.draw_line_soft(self, FIRE_POSITION + Vector2(-26, 12), FIRE_POSITION + Vector2(26, 2), Palette.WOOD_DARK, 6.0)
	DrawKit.draw_line_soft(self, FIRE_POSITION + Vector2(-24, 2), FIRE_POSITION + Vector2(26, 14), Palette.WOOD, 6.0)


func _draw_lanterns() -> void:
	var spots := [Vector2(300.0, 368.0), Vector2(980.0, 372.0), Vector2(640.0, 296.0)]
	for index in spots.size():
		var point: Vector2 = spots[index]
		var pulse := 0.75 + sin(_time * 1.9 + float(index) * 1.4) * 0.2
		DrawKit.draw_ellipse(self, point, Vector2(72, 72), Palette.with_alpha(Palette.LANTERN, 0.08 * pulse))
		DrawKit.draw_ellipse(self, point, Vector2(20, 20), Palette.with_alpha(Palette.LANTERN, 0.45 * pulse))
		DrawKit.draw_ellipse(self, point, Vector2(7, 7), Palette.LANTERN)
