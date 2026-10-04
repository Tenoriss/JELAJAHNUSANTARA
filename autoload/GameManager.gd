extends Node
## GameManager (autoload)
##
## Pusat keadaan game: flag cerita, inventory, alur layar, jeda, catatan budaya,
## dan penerapan "effects" yang ditulis di data dialog/quest.

signal screen_changed(screen_id: String)
signal flag_changed(flag: String, value: Variant)
signal item_gained(item_id: String, amount: int)
signal note_found(note_id: String)
signal toast_requested(text: String, color: Color)
signal banner_requested(title: String, subtitle: String)
signal puzzle_finished(puzzle_id: String, success: bool)

const SCREENS := {
	"main_menu": "res://scenes/ui/MainMenu.tscn",
	"opening": "res://scenes/main/Opening.tscn",
	"village": "res://scenes/world/Village.tscn",
	"ending": "res://scenes/ending/Ending.tscn",
	"credits": "res://scenes/ending/Credits.tscn",
}

const PUZZLE_SCENES := {
	"pattern": "res://scenes/puzzle/PatternPuzzle.tscn",
	"prep": "res://scenes/puzzle/PrepPuzzle.tscn",
}

## Dialog yang dijalankan tepat setelah sebuah puzzle selesai.
const PUZZLE_SUCCESS_DIALOGUES := {
	"pattern": "pak_jaya_sukses",
	"prep": "guyub_siap",
}

const NOTES_PATH := "res://data/notes/cultural_notes.json"

var flags: Dictionary = {}
var inventory: Inventory
var audio: AudioSystem

var main: Node = null
var hud: Node = null
var player: Node = null

var current_screen := ""
var game_started := false
var game_finished := false
var puzzle_active := false
var active_puzzle_id := ""
var transitioning := false
var paused := false
var play_time := 0.0
var notes_found: Array[String] = []
var notes_data: Dictionary = {}

## Posisi spawn yang diminta (dipakai saat memuat save).
var pending_player_position: Variant = null


func _ready() -> void:
	inventory = Inventory.new()
	Inventory.load_catalog()
	audio = AudioSystem.new()
	add_child(audio)
	_load_notes()
	inventory.item_added.connect(_on_item_added)
	# Sinyal quest disambungkan lewat call_deferred supaya urutan autoload di
	# project.godot tidak menentukan hasilnya (QuestManager pasti sudah siap).
	_connect_quest_signals.call_deferred()
	set_process(true)


func _connect_quest_signals() -> void:
	if not QuestManager.quest_started.is_connected(_on_quest_started):
		QuestManager.quest_started.connect(_on_quest_started)
	if not QuestManager.quest_completed.is_connected(_on_quest_completed):
		QuestManager.quest_completed.connect(_on_quest_completed)


func _process(delta: float) -> void:
	if game_started and not paused and not DialogueManager.is_active:
		play_time += delta


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and game_started:
		SaveManager.save_game()


func _load_notes() -> void:
	notes_data.clear()
	if not FileAccess.file_exists(NOTES_PATH):
		push_warning("Data catatan budaya tidak ditemukan")
		return
	var file := FileAccess.open(NOTES_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		notes_data = parsed


# --- Pendaftaran node ------------------------------------------------------

func register_main(node: Node) -> void:
	main = node


func register_hud(node: Node) -> void:
	hud = node


func register_player(node: Node) -> void:
	player = node


# --- Alur layar ------------------------------------------------------------

func new_game() -> void:
	reset_state()
	game_started = true
	pending_player_position = null
	goto_screen("opening", false)


func continue_game() -> bool:
	if not SaveManager.load_game():
		return false
	game_started = true
	return true


func goto_screen(screen_id: String, use_fade := true) -> void:
	if main == null or transitioning:
		return
	if not SCREENS.has(screen_id):
		push_warning("Layar tidak dikenal: " + screen_id)
		return
	transitioning = true
	if main.has_method("change_screen"):
		main.call("change_screen", screen_id, use_fade)
	else:
		transitioning = false


## Dipanggil Main setelah layar baru siap.
func notify_screen_loaded(screen_id: String) -> void:
	current_screen = screen_id
	screen_changed.emit(screen_id)
	if hud != null and hud.has_method("set_hud_visible"):
		hud.call("set_hud_visible", screen_id == "village")


func notify_transition_finished() -> void:
	transitioning = false


func return_to_main_menu() -> void:
	DialogueManager.abort()
	set_paused(false)
	game_started = false
	audio.stop_ambient(0.6)
	audio.play_music("menu", 0.8)
	goto_screen("main_menu")


func finish_game() -> void:
	game_finished = true
	set_flag("game_finished", true)
	SaveManager.save_game()
	goto_screen("ending")


# --- Jeda ------------------------------------------------------------------

func set_paused(value: bool) -> void:
	if paused == value:
		return
	paused = value
	get_tree().paused = value


func toggle_pause() -> void:
	if not game_started or current_screen != "village":
		return
	if DialogueManager.is_active or puzzle_active:
		return
	set_paused(not paused)


func can_player_act() -> bool:
	if not game_started or transitioning or paused or puzzle_active:
		return false
	if DialogueManager.is_active:
		return false
	return true


# --- Flag cerita -----------------------------------------------------------

func set_flag(name: String, value: Variant = true) -> void:
	flags[name] = value
	flag_changed.emit(name, value)


func get_flag(name: String, default: Variant = false) -> Variant:
	return flags.get(name, default)


func has_flag(name: String) -> bool:
	var value: Variant = flags.get(name, false)
	if typeof(value) == TYPE_BOOL:
		return value
	if typeof(value) == TYPE_INT:
		return int(value) != 0
	return not str(value).is_empty()


func clear_flag(name: String) -> void:
	flags.erase(name)
	flag_changed.emit(name, false)


# --- Item ------------------------------------------------------------------

func add_item(item_id: String, amount := 1) -> void:
	inventory.add(item_id, amount)


func has_item(item_id: String, amount := 1) -> bool:
	return inventory.has(item_id, amount)


func remove_item(item_id: String, amount := 1) -> bool:
	return inventory.remove(item_id, amount)


func _on_item_added(item_id: String, amount: int) -> void:
	item_gained.emit(item_id, amount)
	if hud != null and hud.has_method("show_item_toast"):
		hud.call("show_item_toast", item_id, amount)


# --- Catatan budaya --------------------------------------------------------

func find_note(note_id: String) -> void:
	if note_id.is_empty() or notes_found.has(note_id):
		return
	notes_found.append(note_id)
	note_found.emit(note_id)
	audio.play_sfx("note")
	show_toast("Catatan Budaya: " + note_title(note_id), Palette.GOLD_PALE)


func is_note_found(note_id: String) -> bool:
	return notes_found.has(note_id)


func note_title(note_id: String) -> String:
	var data: Dictionary = notes_data.get(note_id, {})
	return str(data.get("title", note_id))


func note_text(note_id: String) -> String:
	var data: Dictionary = notes_data.get(note_id, {})
	return str(data.get("text", ""))


func total_notes() -> int:
	return notes_data.size()


# --- Umpan balik UI --------------------------------------------------------

func show_toast(text: String, color: Color = Palette.CREAM) -> void:
	toast_requested.emit(text, color)


func show_banner(title: String, subtitle := "") -> void:
	banner_requested.emit(title, subtitle)


# --- Puzzle ----------------------------------------------------------------

func start_puzzle(puzzle_id: String) -> void:
	if puzzle_active or not PUZZLE_SCENES.has(puzzle_id):
		return
	active_puzzle_id = puzzle_id
	puzzle_active = true
	DialogueManager.abort()
	if main != null and main.has_method("open_puzzle"):
		main.call("open_puzzle", puzzle_id)
	set_paused(true)


## Dipanggil oleh scene puzzle saat selesai.
func finish_puzzle(puzzle_id: String, success: bool) -> void:
	puzzle_active = false
	active_puzzle_id = ""
	set_paused(false)
	if main != null and main.has_method("close_puzzle"):
		main.call("close_puzzle")
	puzzle_finished.emit(puzzle_id, success)
	if not success:
		return
	set_flag("puzzle_" + puzzle_id + "_done", true)
	audio.play_sfx("success")
	show_toast("Puzzle selesai!", Palette.HINT)
	var dialogue_id: String = PUZZLE_SUCCESS_DIALOGUES.get(puzzle_id, "")
	if not dialogue_id.is_empty():
		await get_tree().create_timer(0.6).timeout
		DialogueManager.start(dialogue_id)


# --- Efek dari data (dialog & quest) --------------------------------------

## Menjalankan "effects" yang ditulis pada data dialog/quest.
func apply_effects(effects: Dictionary) -> void:
	if effects.is_empty():
		return
	if effects.has("sfx"):
		audio.play_sfx(str(effects["sfx"]))
	if effects.has("message"):
		show_toast(str(effects["message"]), Palette.GOLD)
	if effects.has("banner"):
		show_banner(str(effects["banner"]), str(effects.get("banner_subtitle", "")))
	if effects.has("set_flags"):
		for key in effects["set_flags"].keys():
			set_flag(str(key), effects["set_flags"][key])
	if effects.has("clear_flags"):
		for key in effects["clear_flags"]:
			clear_flag(str(key))
	if effects.has("give_items"):
		for item_id in effects["give_items"]:
			add_item(str(item_id))
	if effects.has("remove_items"):
		for item_id in effects["remove_items"]:
			remove_item(str(item_id))
	if effects.has("note"):
		find_note(str(effects["note"]))
	if effects.has("start_quest"):
		QuestManager.start_quest(str(effects["start_quest"]))
	if effects.has("start_quests"):
		for quest_id in effects["start_quests"]:
			QuestManager.start_quest(str(quest_id))
	if effects.has("advance_objectives"):
		for entry in effects["advance_objectives"]:
			QuestManager.advance_objective(
				str(entry.get("quest", "")), str(entry.get("objective", "")), int(entry.get("amount", 1))
			)
	if effects.has("complete_objectives"):
		for entry in effects["complete_objectives"]:
			QuestManager.complete_objective(str(entry.get("quest", "")), str(entry.get("objective", "")))
	if effects.has("complete_quest"):
		QuestManager.complete_quest(str(effects["complete_quest"]))
	if effects.has("complete_quests"):
		for quest_id in effects["complete_quests"]:
			QuestManager.complete_quest(str(quest_id))
	# Aksi yang mengubah layar dijalankan paling akhir dan ditunda satu frame,
	# supaya dialog/puzzle yang sedang memanggilnya sempat ditutup dengan rapi.
	if effects.has("start_puzzle"):
		call_deferred("start_puzzle", str(effects["start_puzzle"]))
	if effects.has("start_dialogue"):
		call_deferred("_deferred_dialogue", str(effects["start_dialogue"]))
	if effects.has("goto_screen"):
		call_deferred("goto_screen", str(effects["goto_screen"]))
	if effects.has("finish_game"):
		call_deferred("finish_game")


func _deferred_dialogue(dialogue_id: String) -> void:
	DialogueManager.start(dialogue_id)


func _on_quest_started(quest: Quest) -> void:
	audio.play_sfx("note", -6.0)
	show_banner("Tujuan Baru", quest.title)


func _on_quest_completed(quest: Quest) -> void:
	audio.play_sfx("quest", -2.0)
	show_banner("Tujuan Selesai", quest.title)
	SaveManager.save_game()


# --- Save / load -----------------------------------------------------------

func reset_state() -> void:
	flags.clear()
	notes_found.clear()
	inventory.clear()
	QuestManager.reset()
	DialogueManager.abort()
	play_time = 0.0
	game_finished = false
	puzzle_active = false
	active_puzzle_id = ""
	pending_player_position = null


func serialize() -> Dictionary:
	var player_position := {}
	if player != null and is_instance_valid(player) and player is Node2D:
		player_position = {"x": player.global_position.x, "y": player.global_position.y}
	return {
		"screen": current_screen,
		"flags": flags.duplicate(),
		"items": inventory.to_dict(),
		"notes": notes_found.duplicate(),
		"quests": QuestManager.serialize(),
		"player": player_position,
		"play_time": play_time,
		"game_finished": game_finished,
		"game_started": game_started,
	}


func deserialize(data: Dictionary) -> void:
	reset_state()
	game_started = bool(data.get("game_started", true))
	game_finished = bool(data.get("game_finished", false))
	play_time = float(data.get("play_time", 0.0))
	var raw_flags: Dictionary = data.get("flags", {})
	for key in raw_flags.keys():
		flags[str(key)] = raw_flags[key]
	var raw_notes: Array = data.get("notes", [])
	for note_id in raw_notes:
		if not notes_found.has(str(note_id)):
			notes_found.append(str(note_id))
	inventory.from_dict(data.get("items", {}))
	QuestManager.deserialize(data.get("quests", {}))
	var raw_position: Dictionary = data.get("player", {})
	if raw_position.has("x") and raw_position.has("y"):
		pending_player_position = Vector2(float(raw_position["x"]), float(raw_position["y"]))
	else:
		pending_player_position = null
