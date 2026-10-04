extends Control
## Kredit akhir.
##
## Dibuat berjalan otomatis dari bawah ke atas dan bisa dihentikan dengan
## tombol di bagian bawah layar.

const SCROLL_SPEED := 38.0
const STAR_COUNT := 60

## Setiap entri: teks, ukuran huruf, warna, dan jeda setelahnya.
const ENTRIES := [
	{"text": "TAPAK NUSA", "size": 44, "color": "gold", "gap": 6.0},
	{"text": "Setiap langkah meninggalkan cerita.", "size": 20, "color": "cream_dim", "gap": 42.0},
	{"text": "SEBUAH CERITA TENTANG GOTONG ROYONG", "size": 16, "color": "cream_dark", "gap": 48.0},
	{"role": "Game Development", "size": 18},
	{"role": "Concept", "size": 18},
	{"role": "Programming", "size": 18},
	{"role": "Game Design", "size": 18},
	{"role": "UI/UX", "size": 18},
	{"role": "Story", "size": 18},
	{"text": "— Fredsa Stanlye —", "size": 24, "color": "gold_pale", "gap": 46.0},
	{"text": "Dibuat dengan Godot 4.x dan GDScript", "size": 17, "color": "cream_dim", "gap": 10.0},
	{"text": "Seluruh gambar dan suara dibuat langsung di dalam game — tanpa aset berhak cipta.", "size": 17, "color": "cream_dim", "gap": 10.0},
	{"text": "Desa Arunika, Raka, dan Guyub Desa adalah cerita fiksi.", "size": 17, "color": "cream_dim", "gap": 10.0},
	{
		"text": "Guyub Desa menggambarkan semangat gotong royong masyarakat Indonesia,\nbukan nama ritual resmi dari daerah tertentu.",
		"size": 17,
		"color": "cream_dim",
		"gap": 40.0,
	},
	{"text": "Terima kasih sudah berjalan bersama Raka.", "size": 22, "color": "hint", "gap": 8.0},
	{"text": "Sampai jumpa di Desa Arunika.", "size": 18, "color": "cream_dim", "gap": 60.0},
]

@onready var clip: Control = $Clip
@onready var roll: VBoxContainer = $Clip/Roll
@onready var back_button: Button = $Footer/BackButton

var _scroll := 0.0
var _roll_height := 0.0
var _time := 0.0
var _stars: Array[Vector2] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager.audio.play_music("ending", 1.0)
	back_button.pressed.connect(_on_back_pressed)
	back_button.mouse_entered.connect(_on_hover)
	_build_stars()
	_build_roll()
	set_process(true)


func _process(delta: float) -> void:
	_time += delta
	_scroll += SCROLL_SPEED * delta
	var view_height := clip.size.y
	if _scroll > _roll_height + view_height:
		_scroll = 0.0
	roll.position = Vector2(roll.position.x, view_height - _scroll)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		_on_back_pressed()


func _on_back_pressed() -> void:
	GameManager.audio.play_ui_click()
	GameManager.return_to_main_menu()


func _on_hover() -> void:
	GameManager.audio.play_sfx("hover", -16.0)


# --- Isi kredit -----------------------------------------------------------

func _build_roll() -> void:
	UiKit.clear(roll)
	for entry in ENTRIES:
		roll.add_child(UiKit.spacer(0.0, 6.0))
		if entry.has("role"):
			var row := UiKit.column(0)
			var role := UiKit.label(str(entry["role"]), 15, Palette.CREAM_DARK)
			role.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			row.add_child(role)
			var name_label := UiKit.label("Fredsa Stanlye", int(entry.get("size", 18)) + 4, Palette.CREAM)
			name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			row.add_child(name_label)
			roll.add_child(row)
		else:
			var label := UiKit.label(str(entry["text"]), int(entry.get("size", 18)), _color(str(entry.get("color", "cream"))))
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			roll.add_child(label)
		roll.add_child(UiKit.spacer(0.0, float(entry.get("gap", 4.0))))
	_roll_height = roll.get_combined_minimum_size().y
	roll.position = Vector2(roll.position.x, clip.size.y)


func _color(key: String) -> Color:
	match key:
		"gold":
			return Palette.GOLD
		"gold_pale":
			return Palette.GOLD_PALE
		"hint":
			return Palette.HINT
		"cream_dim":
			return Palette.CREAM_DIM
		"cream_dark":
			return Palette.CREAM_DARK
		_:
			return Palette.CREAM


func _build_stars() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 771
	for i in STAR_COUNT:
		_stars.append(Vector2(rng.randf_range(0.0, 1280.0), rng.randf_range(0.0, 720.0)))


# --- Latar ----------------------------------------------------------------

func _draw() -> void:
	var screen := get_rect().size
	draw_rect(Rect2(Vector2.ZERO, screen), Palette.NIGHT_SKY)
	for index in _stars.size():
		var star: Vector2 = _stars[index]
		var twinkle := 0.25 + sin(_time * 1.6 + float(index)) * 0.2
		DrawKit.draw_ellipse(self, star, Vector2(1.6, 1.6), Palette.with_alpha(Palette.CREAM, twinkle))
	_draw_footprints(screen)


## Jejak langkah samar, mengingatkan judul game.
func _draw_footprints(screen: Vector2) -> void:
	var path := DrawKit.ellipse_points(Vector2(16.0, 9.0), 16)
	var step := 0
	var x := 90.0
	while x < screen.x - 60.0:
		var phase := float(step) * 1.1 + _time * 0.35
		var y := screen.y * 0.5 + sin(phase) * 120.0
		var color := Palette.with_alpha(Palette.GOLD_DEEP, 0.12)
		DrawKit.draw_poly(self, _offset_points(path, Vector2(x, y)), color)
		DrawKit.draw_poly(self, _offset_points(path, Vector2(x + 42.0, y + 26.0)), color)
		x += 170.0
		step += 1


func _offset_points(points: PackedVector2Array, offset: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for point in points:
		out.append(point + offset)
	return out
