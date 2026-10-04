extends Node
## DialogueManager (autoload)
##
## Membaca semua file di data/dialogue/, memilih cabang dialog sesuai kondisi
## cerita (quest, flag, item, catatan budaya), lalu menampilkan barisnya satu
## per satu lewat DialogueBox.

signal dialogue_started(dialogue_id: String)
signal dialogue_finished(dialogue_id: String)
signal line_shown(line: Dictionary, index: int, total: int)

const DATA_DIR := "res://data/dialogue"

var is_active := false
var current_id := ""
var current_lines: Array = []
var current_index := 0

var _dialogues: Dictionary = {}
var _pending_effects: Dictionary = {}
var _queue: Array[Dictionary] = []
var _box: Node = null


func _ready() -> void:
	load_data()


func load_data() -> void:
	_dialogues.clear()
	var dir := DirAccess.open(DATA_DIR)
	if dir == null:
		push_warning("Folder dialog tidak ditemukan: " + DATA_DIR)
		return
	for file_name in dir.get_files():
		if not file_name.ends_with(".json"):
			continue
		var path := DATA_DIR + "/" + file_name
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			continue
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		file.close()
		if typeof(parsed) != TYPE_DICTIONARY:
			push_warning("Dialog tidak valid: " + path)
			continue
		for key in parsed.keys():
			_dialogues[str(key)] = parsed[key]


## DialogueBox memanggil ini saat siap supaya bisa menerima baris dialog.
func register_box(box: Node) -> void:
	_box = box


func has_dialogue(dialogue_id: String) -> bool:
	return _dialogues.has(dialogue_id)


func dialogue_ids() -> Array:
	return _dialogues.keys()


# --- Memulai dialog --------------------------------------------------------

## Menampilkan dialog menurut id. Mengembalikan false bila tidak ada cabang
## yang cocok dengan kondisi cerita saat ini.
func start(dialogue_id: String) -> bool:
	if dialogue_id.is_empty():
		return false
	if is_active:
		_queue.append({"id": dialogue_id})
		return true
	if not _dialogues.has(dialogue_id):
		push_warning("Dialog tidak ditemukan: " + dialogue_id)
		return false
	var data: Dictionary = _dialogues[dialogue_id]
	var node := _resolve_node(data)
	if node.is_empty():
		return false
	var lines: Array = node.get("lines", [])
	if lines.is_empty():
		return false
	current_id = dialogue_id
	current_lines = lines
	current_index = 0
	_pending_effects = node.get("effects", {})
	is_active = true
	dialogue_started.emit(dialogue_id)
	_show_current()
	return true


## Menampilkan baris dialog langsung (tanpa data JSON) — dipakai untuk dialog
## yang isinya berubah mengikuti keadaan (mis. daftar item yang kurang).
func start_lines(lines: Array, dialogue_id := "dynamic") -> bool:
	if lines.is_empty():
		return false
	if is_active:
		_queue.append({"lines": lines, "id": dialogue_id})
		return true
	current_id = dialogue_id
	current_lines = lines
	current_index = 0
	_pending_effects = {}
	is_active = true
	dialogue_started.emit(dialogue_id)
	_show_current()
	return true


func advance() -> void:
	if not is_active:
		return
	current_index += 1
	if current_index >= current_lines.size():
		_finish()
	else:
		_show_current()


## Menutup dialog tanpa menjalankan efek (dipakai saat pindah layar / reset).
func abort() -> void:
	if not is_active:
		return
	is_active = false
	current_lines = []
	current_index = 0
	_pending_effects = {}
	_queue.clear()
	if _box != null and _box.has_method("hide_box"):
		_box.call("hide_box")


func _show_current() -> void:
	var line: Dictionary = current_lines[current_index]
	line_shown.emit(line, current_index, current_lines.size())
	if _box != null and _box.has_method("show_line"):
		_box.call("show_line", line, current_index < current_lines.size() - 1)


func _finish() -> void:
	var finished_id := current_id
	var effects := _pending_effects
	is_active = false
	current_lines = []
	current_index = 0
	_pending_effects = {}
	if _box != null and _box.has_method("hide_box"):
		_box.call("hide_box")
	dialogue_finished.emit(finished_id)
	if not effects.is_empty():
		GameManager.apply_effects(effects)
	# dialog lanjutan (mis. dialog dipicu oleh efek)
	if not _queue.is_empty():
		var next: Dictionary = _queue.pop_front()
		if next.has("lines"):
			start_lines(next["lines"], str(next.get("id", "dynamic")))
		else:
			start(str(next["id"]))


# --- Pemilihan cabang berdasarkan kondisi ---------------------------------

func _resolve_node(data: Dictionary) -> Dictionary:
	var nodes: Array = data.get("nodes", [])
	var best: Dictionary = {}
	var best_priority := -9999
	for raw in nodes:
		var node: Dictionary = raw
		var conditions: Dictionary = node.get("conditions", {})
		if not _conditions_met(conditions):
			continue
		var priority := int(node.get("priority", 0))
		if priority > best_priority:
			best_priority = priority
			best = node
	return best


func _conditions_met(conditions: Dictionary) -> bool:
	if conditions.is_empty():
		return true
	if conditions.has("quest_active"):
		var any_active := false
		for quest_id in _as_array(conditions["quest_active"]):
			if QuestManager.is_active(str(quest_id)):
				any_active = true
		if not any_active:
			return false
	if conditions.has("quest_completed"):
		var any_completed := false
		for quest_id in _as_array(conditions["quest_completed"]):
			if QuestManager.is_completed(str(quest_id)):
				any_completed = true
		if not any_completed:
			return false
	if conditions.has("quest_not_started"):
		for quest_id in _as_array(conditions["quest_not_started"]):
			if QuestManager.has_started(str(quest_id)):
				return false
	if conditions.has("quest_not_completed"):
		for quest_id in _as_array(conditions["quest_not_completed"]):
			if QuestManager.is_completed(str(quest_id)):
				return false
	if conditions.has("flags"):
		for key in conditions["flags"].keys():
			if GameManager.get_flag(str(key)) != conditions["flags"][key]:
				return false
	if conditions.has("not_flags"):
		for key in conditions["not_flags"].keys():
			if GameManager.get_flag(str(key)) == conditions["not_flags"][key]:
				return false
	if conditions.has("items"):
		for item_id in _as_array(conditions["items"]):
			if not GameManager.has_item(str(item_id)):
				return false
	if conditions.has("missing_items"):
		for item_id in _as_array(conditions["missing_items"]):
			if GameManager.has_item(str(item_id)):
				return false
	if conditions.has("notes"):
		for note_id in _as_array(conditions["notes"]):
			if not GameManager.is_note_found(str(note_id)):
				return false
	if conditions.has("game_finished"):
		if GameManager.game_finished != bool(conditions["game_finished"]):
			return false
	return true


func _as_array(value: Variant) -> Array:
	if typeof(value) == TYPE_ARRAY:
		return value
	return [value]
