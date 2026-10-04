extends Node
## QuestManager (autoload)
##
## Memuat daftar quest dari data/quests/quests.json, menyimpan progres, dan
## menjalankan efek yang tertulis di data (on_start / on_complete).

signal quest_started(quest: Quest)
signal quest_completed(quest: Quest)
signal quest_updated(quest: Quest)
signal objective_completed(quest: Quest, objective: Dictionary)

const DATA_PATH := "res://data/quests/quests.json"

var quests: Dictionary = {}  # id -> Quest
var order_list: Array[String] = []

var _applying := false


func _ready() -> void:
	load_data()


func load_data() -> void:
	quests.clear()
	order_list.clear()
	if not FileAccess.file_exists(DATA_PATH):
		push_warning("Data quest tidak ditemukan: " + DATA_PATH)
		return
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		push_warning("Gagal membuka data quest")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Format data quest tidak valid")
		return
	for quest_id in parsed.keys():
		var raw: Dictionary = parsed[quest_id]
		var quest := Quest.new()
		raw["id"] = quest_id
		quest.setup(raw)
		quests[quest_id] = quest
		order_list.append(quest_id)
	order_list.sort_custom(_sort_by_order)


func _sort_by_order(a: String, b: String) -> bool:
	return quests[a].order < quests[b].order


func reset() -> void:
	for quest in quests.values():
		quest.status = Quest.Status.INACTIVE
		for objective in quest.objectives:
			objective["progress"] = 0


# --- Query -----------------------------------------------------------------

func get_quest(quest_id: String) -> Quest:
	return quests.get(quest_id)


func is_active(quest_id: String) -> bool:
	var quest: Quest = quests.get(quest_id)
	return quest != null and quest.is_active()


func is_completed(quest_id: String) -> bool:
	var quest: Quest = quests.get(quest_id)
	return quest != null and quest.is_completed()


func has_started(quest_id: String) -> bool:
	var quest: Quest = quests.get(quest_id)
	return quest != null and quest.status != Quest.Status.INACTIVE


## Quest aktif pertama (dipakai sebagai penunjuk tujuan utama di HUD).
func get_current() -> Quest:
	for quest_id in order_list:
		var quest: Quest = quests[quest_id]
		if quest.is_active():
			return quest
	return null


func get_active_quests() -> Array[Quest]:
	var out: Array[Quest] = []
	for quest_id in order_list:
		var quest: Quest = quests[quest_id]
		if quest.is_active():
			out.append(quest)
	return out


func get_completed_quests() -> Array[Quest]:
	var out: Array[Quest] = []
	for quest_id in order_list:
		var quest: Quest = quests[quest_id]
		if quest.is_completed():
			out.append(quest)
	return out


# --- Aksi ------------------------------------------------------------------

func start_quest(quest_id: String) -> bool:
	var quest: Quest = quests.get(quest_id)
	if quest == null or quest.status != Quest.Status.INACTIVE:
		return false
	quest.status = Quest.Status.ACTIVE
	quest_started.emit(quest)
	quest_updated.emit(quest)
	_apply_effects(quest.on_start)
	_check_auto_complete(quest)
	return true


func complete_objective(quest_id: String, objective_id: String) -> void:
	var quest: Quest = quests.get(quest_id)
	if quest == null or quest.is_completed():
		return
	var objective := quest.objective(objective_id)
	if objective.is_empty() or quest.is_objective_done(objective_id):
		return
	quest.add_progress(objective_id, int(objective["required"]))
	objective_completed.emit(quest, objective)
	quest_updated.emit(quest)
	_check_auto_complete(quest)


func advance_objective(quest_id: String, objective_id: String, amount := 1) -> void:
	var quest: Quest = quests.get(quest_id)
	if quest == null or quest.is_completed():
		return
	var objective := quest.objective(objective_id)
	if objective.is_empty():
		return
	if quest.is_objective_done(objective_id):
		return
	quest.add_progress(objective_id, amount)
	if quest.is_objective_done(objective_id):
		objective_completed.emit(quest, objective)
	quest_updated.emit(quest)
	_check_auto_complete(quest)


func complete_quest(quest_id: String) -> void:
	var quest: Quest = quests.get(quest_id)
	if quest == null or quest.is_completed():
		return
	for objective in quest.objectives:
		objective["progress"] = int(objective["required"])
	quest.status = Quest.Status.COMPLETED
	quest_completed.emit(quest)
	quest_updated.emit(quest)
	_apply_effects(quest.on_complete)


func _check_auto_complete(quest: Quest) -> void:
	if quest.is_active() and quest.all_objectives_done():
		complete_quest(quest.id)


func _apply_effects(effects: Dictionary) -> void:
	if effects.is_empty() or _applying:
		return
	_applying = true
	GameManager.apply_effects(effects)
	_applying = false


# --- Save / load -----------------------------------------------------------

func serialize() -> Dictionary:
	var out := {}
	for quest_id in quests.keys():
		out[quest_id] = quests[quest_id].to_dict()
	return out


func deserialize(data: Dictionary) -> void:
	reset()
	for quest_id in data.keys():
		var quest: Quest = quests.get(quest_id)
		if quest != null and typeof(data[quest_id]) == TYPE_DICTIONARY:
			quest.from_dict(data[quest_id])
