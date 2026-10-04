class_name PlayerInteractor
extends Area2D
## Mendeteksi Interactable terdekat dan menangani tombol interaksi (E).

var current: Interactable = null

var _candidates: Array[Interactable] = []


func _ready() -> void:
	monitoring = true
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	set_process(true)


func _process(_delta: float) -> void:
	_refresh_current()


func _on_area_entered(area: Area2D) -> void:
	if area is Interactable:
		var interactable: Interactable = area
		if not _candidates.has(interactable):
			_candidates.append(interactable)


func _on_area_exited(area: Area2D) -> void:
	if area is Interactable:
		var interactable: Interactable = area
		_candidates.erase(interactable)
		if current == interactable:
			current = null
		interactable.set_focused(false)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return
	if try_interact():
		get_viewport().set_input_as_handled()


## Mengembalikan true jika ada interaksi yang dijalankan.
func try_interact() -> bool:
	_refresh_current()
	if current == null:
		return false
	if not current.can_interact():
		return false
	var target := current
	target.set_focused(false)
	target.interact()
	return true


func _refresh_current() -> void:
	var best: Interactable = null
	var best_distance := INF
	var here := global_position
	for i in range(_candidates.size() - 1, -1, -1):
		var candidate := _candidates[i]
		if not is_instance_valid(candidate):
			_candidates.remove_at(i)
			continue
		if not candidate.can_interact():
			candidate.set_focused(false)
			continue
		var distance := here.distance_squared_to(candidate.global_position)
		if distance < best_distance:
			best_distance = distance
			best = candidate
	if best == current:
		return
	if current != null and is_instance_valid(current):
		current.set_focused(false)
	current = best
	if current != null:
		current.set_focused(true)
