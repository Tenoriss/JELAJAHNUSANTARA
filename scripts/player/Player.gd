class_name Player
extends CharacterBody2D
## Raka — karakter yang dikendalikan pemain.
##
## Tidak ada pertarungan: pemain berjalan, berbicara, mengambil barang, dan
## menyelesaikan puzzle. Pergerakan memakai percepatan sederhana supaya terasa
## halus tapi tetap responsif.

@export var move_speed := 172.0
@export var acceleration := 1500.0
@export var friction := 2000.0
@export var footsteps_enabled := true

@onready var visual: CharacterVisual = $Visual
@onready var camera: Camera2D = $Camera2D
@onready var interactor: PlayerInteractor = $Interactor

var facing := Vector2.DOWN
var _step_timer := 0.0
var _step_alt := false


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	GameManager.register_player(self)


func _physics_process(delta: float) -> void:
	var input := Vector2.ZERO
	if GameManager.can_player_act():
		input = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	var target := input * move_speed
	if input.length_squared() > 0.01:
		velocity = velocity.move_toward(target, acceleration * delta)
		facing = input.normalized()
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	move_and_slide()
	_update_visual(delta)


func _update_visual(delta: float) -> void:
	var speed := velocity.length()
	var ratio := clampf(speed / move_speed, 0.0, 1.0)
	visual.facing = facing
	visual.speed_ratio = ratio
	if ratio > 0.05 and footsteps_enabled:
		_step_timer += delta * (0.7 + ratio)
		if _step_timer >= 0.42:
			_step_timer = 0.0
			_step_alt = not _step_alt
			GameManager.audio.play_sfx(
				"step1" if _step_alt else "step2", -16.0, randf_range(0.94, 1.08)
			)
	else:
		_step_timer = 0.3


## Dipakai dunia untuk menempatkan pemain (spawn / memuat save).
func teleport_to(target: Vector2) -> void:
	global_position = target
	velocity = Vector2.ZERO
	if camera != null:
		camera.reset_smoothing()


## Menampilkan pemain beserta kamera setelah layar siap.
func activate(active: bool) -> void:
	visible = active
	set_physics_process(active)
	if camera != null:
		camera.enabled = active
