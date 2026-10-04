extends Node
## SaveManager (autoload)
##
## Save game memakai JSON (user://savegame.json) dan pengaturan memakai
## ConfigFile (user://settings.cfg). Tidak ada database, tidak ada server.

signal settings_changed()
signal game_saved()
signal game_loaded()

const SAVE_PATH := "user://savegame.json"
const SETTINGS_PATH := "user://settings.cfg"
const SAVE_VERSION := 1

const DEFAULT_SETTINGS := {
	"music": 0.7,
	"sfx": 0.85,
	"ambient": 0.5,
	"fullscreen": false,
}

var settings := DEFAULT_SETTINGS.duplicate()


func _ready() -> void:
	load_settings()
	apply_settings()


# --- Save game -------------------------------------------------------------

func has_save() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	return not read_save().is_empty()


func read_save() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Save game rusak, diabaikan")
		return {}
	return parsed


## Ringkasan isi save untuk ditampilkan di menu utama.
func save_summary() -> Dictionary:
	var data := read_save()
	if data.is_empty():
		return {}
	var quest_title := ""
	var quests: Dictionary = data.get("quests", {})
	for quest_id in quests.keys():
		var entry: Dictionary = quests[quest_id]
		if int(entry.get("status", 0)) == Quest.Status.ACTIVE and quest_title.is_empty():
			var quest: Quest = QuestManager.get_quest(str(quest_id))
			if quest != null:
				quest_title = quest.title
	return {
		"saved_at": str(data.get("saved_at", "")),
		"play_time": float(data.get("play_time", 0.0)),
		"quest": quest_title,
		"finished": bool(data.get("game_finished", false)),
		"notes": (data.get("notes", []) as Array).size(),
	}


func save_game(silent := true) -> bool:
	if not GameManager.game_started:
		return false
	var data := GameManager.serialize()
	data["version"] = SAVE_VERSION
	data["saved_at"] = Time.get_datetime_string_from_system(false, true)
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Tidak bisa menulis save game: %s" % FileAccess.get_open_error())
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	game_saved.emit()
	if not silent:
		GameManager.show_toast("Permainan tersimpan", Palette.HINT)
	return true


func load_game() -> bool:
	var data := read_save()
	if data.is_empty():
		return false
	GameManager.deserialize(data)
	game_loaded.emit()
	var screen := str(data.get("screen", "village"))
	if screen != "village":
		screen = "village"
	GameManager.goto_screen(screen, false)
	return true


func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var dir := DirAccess.open("user://")
		if dir != null:
			dir.remove("savegame.json")


# --- Pengaturan ------------------------------------------------------------

func load_settings() -> void:
	settings = DEFAULT_SETTINGS.duplicate()
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		for key in DEFAULT_SETTINGS.keys():
			settings[key] = config.get_value("settings", key, DEFAULT_SETTINGS[key])


func save_settings() -> void:
	var config := ConfigFile.new()
	for key in settings.keys():
		config.set_value("settings", key, settings[key])
	config.save(SETTINGS_PATH)


func set_setting(key: String, value: Variant) -> void:
	if not settings.has(key):
		return
	settings[key] = value
	apply_settings()
	save_settings()
	settings_changed.emit()


func get_setting(key: String) -> Variant:
	return settings.get(key, DEFAULT_SETTINGS.get(key))


func apply_settings() -> void:
	if GameManager.audio != null:
		GameManager.audio.set_music_volume(float(settings["music"]))
		GameManager.audio.set_sfx_volume(float(settings["sfx"]))
		GameManager.audio.set_ambient_volume(float(settings["ambient"]))
	var want_fullscreen := bool(settings["fullscreen"])
	var mode := DisplayServer.window_get_mode()
	var is_fullscreen := mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	if want_fullscreen != is_fullscreen:
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_FULLSCREEN if want_fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		)


# --- Utilitas --------------------------------------------------------------

static func format_play_time(seconds: float) -> String:
	var total := int(seconds)
	return "%02d:%02d" % [total / 60, total % 60]
