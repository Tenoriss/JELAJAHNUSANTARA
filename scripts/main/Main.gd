extends Node
## Main — akar permainan.
##
## Mengatur pergantian layar (menu, pembuka, desa, penutup, kredit), efek
## memudar, lapisan puzzle, dan meneruskan tombol global (ESC, SPACE/E, Q)
## ke dialog atau menu.

const FADE_TIME := 0.42

@onready var screens: Node = $Screens
@onready var hud: Hud = $Hud
@onready var dialogue_box: DialogueBox = $DialogueBox
@onready var menu_layer: MenuLayer = $MenuLayer
@onready var puzzle_layer: CanvasLayer = $PuzzleLayer
@onready var fade: ColorRect = $FadeLayer/Fade

var _screen: Node = null
var _puzzle: Node = null
var _fade_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	puzzle_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager.register_main(self)
	fade.color.a = 1.0
	fade.visible = true
	change_screen("village" if GameManager.game_started else "main_menu", false)


# --- Pergantian layar -----------------------------------------------------

func change_screen(screen_id: String, use_fade := true) -> void:
	var path: String = GameManager.SCREENS.get(screen_id, "")
	if path.is_empty():
		push_warning("Layar tidak dikenal: " + screen_id)
		GameManager.notify_transition_finished()
		return
	if use_fade:
		await _fade_to(1.0, FADE_TIME)
	_swap_screen(path)
	GameManager.notify_screen_loaded(screen_id)
	if use_fade:
		await _fade_to(0.0, FADE_TIME)
	else:
		fade.color.a = 0.0
		fade.visible = false
	GameManager.notify_transition_finished()
	if _screen != null and is_instance_valid(_screen) and _screen.has_method("notify_screen_ready"):
		_screen.call("notify_screen_ready")


func _swap_screen(path: String) -> void:
	if _screen != null and is_instance_valid(_screen):
		screens.remove_child(_screen)
		_screen.queue_free()
	_screen = null
	var packed := load(path) as PackedScene
	if packed == null:
		push_error("Gagal memuat layar: " + path)
		return
	_screen = packed.instantiate()
	_screen.process_mode = Node.PROCESS_MODE_PAUSABLE
	screens.add_child(_screen)


func _fade_to(target: float, duration: float) -> void:
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	fade.visible = true
	_fade_tween = create_tween()
	_fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_fade_tween.tween_property(fade, "color:a", target, duration)
	await get_tree().create_timer(duration).timeout
	fade.visible = target > 0.01


# --- Puzzle ---------------------------------------------------------------

func open_puzzle(puzzle_id: String) -> void:
	var path: String = GameManager.PUZZLE_SCENES.get(puzzle_id, "")
	if path.is_empty():
		return
	close_puzzle()
	var packed := load(path) as PackedScene
	if packed == null:
		push_error("Gagal memuat puzzle: " + path)
		return
	_puzzle = packed.instantiate()
	puzzle_layer.add_child(_puzzle)


func close_puzzle() -> void:
	if _puzzle != null and is_instance_valid(_puzzle):
		puzzle_layer.remove_child(_puzzle)
		_puzzle.queue_free()
	_puzzle = null


# --- Tombol global --------------------------------------------------------

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_on_pause_pressed()
		return
	if GameManager.puzzle_active:
		return
	if DialogueManager.is_active:
		if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
			dialogue_box.request_advance()
			get_viewport().set_input_as_handled()
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			dialogue_box.request_advance()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("journal"):
		get_viewport().set_input_as_handled()
		if menu_layer.is_open():
			menu_layer.back()
		elif GameManager.current_screen == "village" and GameManager.game_started:
			menu_layer.open_quests()


func _on_pause_pressed() -> void:
	# Saat dialog berjalan, ESC tidak membuka menu: pemain menyelesaikan
	# dialognya dulu (atau menekan E/SPACE untuk lanjut).
	if DialogueManager.is_active:
		return
	if GameManager.puzzle_active:
		get_viewport().set_input_as_handled()
		if _puzzle != null and _puzzle.has_method("cancel"):
			_puzzle.call("cancel")
		return
	if menu_layer.is_open():
		get_viewport().set_input_as_handled()
		menu_layer.back()
		return
	if GameManager.current_screen == "village" and GameManager.game_started:
		get_viewport().set_input_as_handled()
		menu_layer.open_pause()
		return
	# Layar lain (pembuka, penutup, kredit, menu utama) menangani ESC sendiri.
