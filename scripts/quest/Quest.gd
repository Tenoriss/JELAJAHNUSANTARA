class_name Quest
extends RefCounted
## Data satu quest beserta progresnya.
##
## Objective disimpan sebagai Dictionary agar mudah dibaca dari JSON:
##   {"id": "o_bambu", "text": "Ambil bambu", "required": 1, "progress": 0}

enum Status { INACTIVE, ACTIVE, COMPLETED }

var id := ""
var title := ""
var description := ""
var order := 0
var status := Status.INACTIVE
var objectives: Array[Dictionary] = []
var on_start: Dictionary = {}
var on_complete: Dictionary = {}
var next_quest := ""


func setup(data: Dictionary) -> Quest:
	id = str(data.get("id", id))
	title = str(data.get("title", id))
	description = str(data.get("description", ""))
	order = int(data.get("order", 0))
	on_start = data.get("on_start", {})
	on_complete = data.get("on_complete", {})
	next_quest = str(data.get("next_quest", ""))
	objectives.clear()
	for raw in data.get("objectives", []):
		var objective: Dictionary = {
			"id": str(raw.get("id", "")),
			"text": str(raw.get("text", "")),
			"required": int(raw.get("required", 1)),
			"progress": 0,
			"item": str(raw.get("item", "")),
		}
		objectives.append(objective)
	return self


func objective(objective_id: String) -> Dictionary:
	for objective in objectives:
		if objective["id"] == objective_id:
			return objective
	return {}


func progress(objective_id: String) -> int:
	var objective := self.objective(objective_id)
	return int(objective.get("progress", 0))


func is_objective_done(objective_id: String) -> bool:
	var objective := self.objective(objective_id)
	if objective.is_empty():
		return false
	return int(objective["progress"]) >= int(objective["required"])


func set_progress(objective_id: String, value: int) -> void:
	var objective := self.objective(objective_id)
	if objective.is_empty():
		return
	objective["progress"] = clampi(value, 0, int(objective["required"]))


func add_progress(objective_id: String, amount := 1) -> void:
	var objective := self.objective(objective_id)
	if objective.is_empty():
		return
	set_progress(objective_id, int(objective["progress"]) + amount)


func all_objectives_done() -> bool:
	for objective in objectives:
		if int(objective["progress"]) < int(objective["required"]):
			return false
	return true


func is_active() -> bool:
	return status == Status.ACTIVE


func is_completed() -> bool:
	return status == Status.COMPLETED


func total_required() -> int:
	var total := 0
	for objective in objectives:
		total += int(objective["required"])
	return total


func total_progress() -> int:
	var total := 0
	for objective in objectives:
		total += mini(int(objective["progress"]), int(objective["required"]))
	return total


func to_dict() -> Dictionary:
	var progress_list: Array = []
	for objective in objectives:
		progress_list.append(int(objective["progress"]))
	return {"status": status, "progress": progress_list}


func from_dict(data: Dictionary) -> void:
	status = int(data.get("status", Status.INACTIVE))
	var progress_list: Array = data.get("progress", [])
	for i in mini(progress_list.size(), objectives.size()):
		objectives[i]["progress"] = int(progress_list[i])
