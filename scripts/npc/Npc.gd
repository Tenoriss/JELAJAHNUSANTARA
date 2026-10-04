class_name Npc
extends Interactable
## NPC utama TAPAK NUSA.
##
## Satu NPC = satu Interactable + visual prosedural + badan statis. Dialognya
## dipilih otomatis lewat kondisi cerita di data/dialogue/.

@export var npc_id := ""
@export var display_name := ""
@export var dialogue_id := ""
@export var palette_id := ""
@export var start_facing := Vector2.DOWN
## Menoleh ke arah pemain bila pemain berdiri dekat.
@export var looks_at_player := true
@export var look_radius := 78.0

## NPC bisa berpindah tempat mengikuti cerita.
@export var alt_quest := ""
@export var alt_position := Vector2.ZERO
## Posisi saat acara Guyub Desa berlangsung (flag "event_ready").
@export var gather_position := Vector2.ZERO

## Jalur jalan santai (posisi relatif terhadap titik awal). Kosong = diam.
@export var wander_points: PackedVector2Array = PackedVector2Array()
@export var wander_speed := 26.0
@export var wander_pause := 1.8

var visual: CharacterVisual = null

var _wander_index := 0
var _wander_timer := 0.0
var _home := Vector2.ZERO


func _ready() -> void:
	super._ready()
	prompt_icon = "talk"
	if prompt_text == "Berinteraksi":
		prompt_text = "Bicara dengan " + (display_name if not display_name.is_empty() else "warga")
	visual = get_node_or_null("Visual") as CharacterVisual
	if visual != null:
		visual.palette_id = palette_id if not palette_id.is_empty() else npc_id
		visual.facing = start_facing
	_home = global_position
	_apply_story_position()
	if wander_points.size() > 0:
		set_physics_process(true)


## Memindahkan NPC sesuai keadaan cerita (dimuat setelah save juga).
func _apply_story_position() -> void:
	var target := Vector2.ZERO
	if GameManager.get_flag("event_ready") and gather_position != Vector2.ZERO:
		target = gather_position
	elif not alt_quest.is_empty() and alt_position != Vector2.ZERO and QuestManager.is_active(alt_quest):
		target = alt_position
	if target != Vector2.ZERO:
		global_position = target
		_home = target


## Memindahkan NPC ke titik berkumpul (dipakai saat acara Guyub Desa dimulai).
func apply_gather_position() -> void:
	if gather_position == Vector2.ZERO:
		return
	global_position = gather_position
	_home = gather_position
	wander_points = PackedVector2Array()
	_wander_timer = 0.0
	if visual != null:
		visual.speed_ratio = 0.0


func interact() -> void:
	if not can_interact():
		return
	_turn_to_player()
	interacted.emit(self)
	GameManager.set_flag("met_" + npc_id, true)
	if not dialogue_id.is_empty():
		DialogueManager.start(dialogue_id)


func _physics_process(delta: float) -> void:
	if wander_points.is_empty() or visual == null:
		return
	if _wander_timer > 0.0:
		_wander_timer -= delta
		visual.speed_ratio = 0.0
		return
	var target := _home + wander_points[_wander_index]
	var to_target := target - global_position
	if to_target.length() < 4.0:
		_wander_index = (_wander_index + 1) % wander_points.size()
		_wander_timer = wander_pause
		visual.speed_ratio = 0.0
		return
	global_position += to_target.normalized() * wander_speed * delta
	visual.facing = to_target.normalized()
	visual.speed_ratio = 0.8


func _turn_to_player() -> void:
	if not looks_at_player or visual == null:
		return
	var player_node := GameManager.player as Node2D
	if player_node == null:
		return
	if global_position.distance_to(player_node.global_position) <= look_radius:
		visual.face_towards(player_node.global_position)
