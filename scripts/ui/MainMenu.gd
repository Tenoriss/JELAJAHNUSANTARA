class_name MainMenu
extends Control
## Menu utama TAPAK NUSA.
##
## Latar digambar langsung dengan kode (langit senja, rumah desa, sawah, dan
## lentera) supaya game tetap punya identitas visual tanpa aset luar.

const REDRAW_INTERVAL := 1.0 / 30.0

@onready var start_button: Button = $Menu/StartButton
@onready var continue_button: Button = $Menu/ContinueButton
@onready var settings_button: Button = $Menu/SettingsButton
@onready var quit_button: Button = $Menu/QuitButton
@onready var save_info: Label = $SaveInfo
@onready var settings_panel: SettingsPanel = $SettingsPanel

var _time := 0.0
var _redraw_timer := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager.audio.stop_ambient(0.8)
	GameManager.audio.play_music("menu", 0.9)
	start_button.pressed.connect(_on_start_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	settings_panel.closed.connect(_on_settings_closed)
	for button in [start_button, continue_button, settings_button, quit_button]:
		button.mouse_entered.connect(_on_button_hover)
	_refresh()
	set_process(true)


func _process(delta: float) -> void:
	_time += delta
	_redraw_timer += delta
	if _redraw_timer >= REDRAW_INTERVAL:
		_redraw_timer = 0.0
		queue_redraw()


# --- Isi menu -------------------------------------------------------------

func _refresh() -> void:
	var has_save := SaveManager.has_save()
	continue_button.disabled = not has_save
	save_info.text = _save_text() if has_save else "Belum ada perjalanan yang tersimpan."
	if not settings_panel.visible:
		start_button.grab_focus()


func _save_text() -> String:
	var summary := SaveManager.save_summary()
	if summary.is_empty():
		return "Belum ada perjalanan yang tersimpan."
	var seconds := float(summary.get("play_time", 0.0))
	var quest := str(summary.get("quest", ""))
	var text := "Lanjutkan perjalanan — %d menit bermain" % (int(seconds) / 60)
	if not quest.is_empty():
		text += "  ·  Tujuan: " + quest
	if bool(summary.get("finished", false)):
		text += "  ·  cerita sudah tamat"
	return text


# --- Aksi -----------------------------------------------------------------

func _on_start_pressed() -> void:
	GameManager.audio.play_ui_click()
	GameManager.new_game()


func _on_continue_pressed() -> void:
	GameManager.audio.play_ui_click()
	GameManager.continue_game()


func _on_settings_pressed() -> void:
	GameManager.audio.play_ui_click()
	settings_panel.open()


func _on_quit_pressed() -> void:
	GameManager.audio.play_ui_click()
	get_tree().quit()


func _on_settings_closed() -> void:
	_refresh()


func _on_button_hover() -> void:
	GameManager.audio.play_sfx("hover", -16.0)


# --- Latar belakang prosedural -------------------------------------------

func _draw() -> void:
	var screen := get_rect().size
	_draw_sky(screen)
	_draw_hills(screen)
	_draw_village(screen)
	_draw_field(screen)
	_draw_lanterns(screen)


func _draw_sky(screen: Vector2) -> void:
	var bands := [
		[Palette.DUSK_HIGH, 0.0, 0.42],
		[Palette.mix(Palette.DUSK_HIGH, Palette.DUSK_SKY, 0.55), 0.42, 0.22],
		[Palette.DUSK_SKY, 0.64, 0.2],
		[Palette.mix(Palette.DUSK_SKY, Palette.GOLD_PALE, 0.45), 0.84, 0.16],
	]
	for band in bands:
		var color: Color = band[0]
		draw_rect(
			Rect2(0, screen.y * float(band[1]), screen.x, screen.y * float(band[2]) + 1.0), color
		)
	var sun := Vector2(screen.x * 0.72, screen.y * 0.72)
	DrawKit.draw_ellipse(self, sun, Vector2(120, 120), Palette.with_alpha(Palette.GOLD_PALE, 0.12))
	DrawKit.draw_ellipse(self, sun, Vector2(74, 74), Palette.with_alpha(Palette.GOLD_PALE, 0.22))
	DrawKit.draw_ellipse(self, sun, Vector2(44, 44), Palette.with_alpha(Palette.LANTERN, 0.85))


func _draw_hills(screen: Vector2) -> void:
	var base := screen.y * 0.78
	DrawKit.draw_ellipse(self, Vector2(screen.x * 0.2, base + 60.0), Vector2(520, 190), Palette.with_alpha(Palette.LEAF_DARK, 0.55))
	DrawKit.draw_ellipse(self, Vector2(screen.x * 0.75, base + 40.0), Vector2(600, 210), Palette.with_alpha(Palette.GRASS_DARK, 0.7))
	DrawKit.draw_ellipse(self, Vector2(screen.x * 0.5, base + 120.0), Vector2(760, 200), Palette.with_alpha(Palette.NIGHT_SKY, 0.35))


func _draw_village(screen: Vector2) -> void:
	var ground := screen.y * 0.82
	draw_rect(Rect2(0, ground, screen.x, screen.y - ground), Palette.GRASS_DARK)
	_draw_house(Vector2(screen.x * 0.18, ground + 6.0), 0.85)
	_draw_house(Vector2(screen.x * 0.34, ground + 26.0), 1.0)
	_draw_house(Vector2(screen.x * 0.58, ground + 12.0), 0.92)
	_draw_tree(Vector2(screen.x * 0.86, ground + 18.0), 1.0)
	var fence := Palette.with_alpha(Palette.BAMBOO_DARK, 0.8)
	var index := 0
	while index < 26:
		var x := screen.x * 0.04 + float(index) * 22.0
		if x > screen.x * 0.5:
			break
		DrawKit.draw_line_soft(self, Vector2(x, ground - 6.0), Vector2(x, ground - 30.0), fence, 3.0)
		index += 1
	DrawKit.draw_line_soft(
		self, Vector2(screen.x * 0.04, ground - 26.0), Vector2(screen.x * 0.46, ground - 26.0), fence, 2.0
	)


func _draw_house(base: Vector2, scale: float) -> void:
	var width := 150.0 * scale
	var wall_height := 78.0 * scale
	var body := Rect2(base.x - width * 0.5, base.y - wall_height, width, wall_height)
	DrawKit.draw_box(self, body, Palette.WOOD_DARK, 4)
	DrawKit.draw_box(self, Rect2(body.position.x, body.position.y, body.size.x, 8.0 * scale), Palette.WOOD, 3)
	DrawKit.draw_poly(
		self,
		PackedVector2Array(
			[
				Vector2(body.position.x - 16.0 * scale, body.position.y),
				Vector2(base.x, body.position.y - 54.0 * scale),
				Vector2(body.end.x + 16.0 * scale, body.position.y),
			]
		),
		Palette.ROOF_SHADOW
	)
	DrawKit.draw_poly(
		self,
		PackedVector2Array(
			[
				Vector2(body.position.x - 16.0 * scale, body.position.y),
				Vector2(base.x, body.position.y - 54.0 * scale),
				Vector2(base.x, body.position.y),
			]
		),
		Palette.ROOF_TILE
	)
	var glow := 0.6 + sin(_time * 1.4 + base.x * 0.01) * 0.15
	DrawKit.draw_box(
		self,
		Rect2(base.x - 16.0 * scale, base.y - 46.0 * scale, 32.0 * scale, 26.0 * scale),
		Palette.with_alpha(Palette.LANTERN, glow),
		3
	)
	DrawKit.draw_box(
		self,
		Rect2(base.x - 2.0 * scale, base.y - 46.0 * scale, 4.0 * scale, 26.0 * scale),
		Palette.WOOD_DARK,
		1
	)


func _draw_tree(base: Vector2, scale: float) -> void:
	DrawKit.draw_pillar(self, base, 12.0 * scale, 90.0 * scale, Palette.WOOD, Palette.WOOD_DARK)
	var sway := sin(_time * 0.8) * 3.0
	DrawKit.draw_ellipse(self, base + Vector2(0.0, -100.0 * scale + sway), Vector2(74, 54), Palette.LEAF_DARK)
	DrawKit.draw_ellipse(self, base + Vector2(-34.0 * scale, -84.0 * scale + sway), Vector2(48, 36), Palette.LEAF)
	DrawKit.draw_ellipse(self, base + Vector2(38.0 * scale, -92.0 * scale + sway), Vector2(52, 38), Palette.LEAF_LIGHT)


func _draw_field(screen: Vector2) -> void:
	var top := screen.y * 0.9
	var lines := Palette.with_alpha(Palette.RICE_GOLD, 0.5)
	var index := 0
	while index < 16:
		var y := top + float(index) * 7.0
		if y > screen.y:
			break
		DrawKit.draw_line_soft(self, Vector2(0, y), Vector2(screen.x, y), lines, 2.0)
		index += 1
	DrawKit.draw_band(
		self,
		Vector2(screen.x * 0.42, screen.y),
		Vector2(screen.x * 0.5, screen.y * 0.84),
		120.0,
		Palette.with_alpha(Palette.PATH_SAND, 0.75)
	)


func _draw_lanterns(screen: Vector2) -> void:
	var spots := [
		Vector2(screen.x * 0.07, screen.y * 0.62),
		Vector2(screen.x * 0.45, screen.y * 0.58),
		Vector2(screen.x * 0.93, screen.y * 0.66),
	]
	for index in spots.size():
		var point: Vector2 = spots[index]
		var pulse := 0.7 + sin(_time * 1.6 + float(index) * 1.3) * 0.25
		DrawKit.draw_ellipse(self, point, Vector2(46, 46), Palette.with_alpha(Palette.LANTERN, 0.1 * pulse))
		DrawKit.draw_ellipse(self, point, Vector2(16, 16), Palette.with_alpha(Palette.LANTERN, 0.5 * pulse))
		DrawKit.draw_ellipse(self, point, Vector2(6, 6), Palette.LANTERN)
