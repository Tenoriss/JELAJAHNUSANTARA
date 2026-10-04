class_name Village
extends Node2D
## Desa Arunika — peta utama game.
##
## Scene ini menempatkan pemain, mengatur batas kamera, dan menyesuaikan
## keadaan desa dengan progres cerita (mis. lampu menyala dan warga berkumpul
## setelah perlengkapan acara selesai).

@export var map_bounds := Rect2(0, 0, 3200, 2000)
@export var spawn_point := Vector2(220, 1020)
@export var music_track := "village"
@export var ambient_track := "day"
@export var leave_particles := true

@onready var entities: Node2D = $Entities
@onready var player: Player = $Entities/Player

var _ambient_created := false


func _ready() -> void:
	GameManager.register_player(player)
	_setup_camera()
	_place_player()
	_ensure_quest()
	_apply_world_state()
	GameManager.audio.play_music(music_track)
	GameManager.audio.play_ambient(ambient_track)
	GameManager.flag_changed.connect(_on_flag_changed)
	if leave_particles:
		_create_leaf_particles()


func _exit_tree() -> void:
	if GameManager.flag_changed.is_connected(_on_flag_changed):
		GameManager.flag_changed.disconnect(_on_flag_changed)
	if GameManager.player == player:
		GameManager.register_player(null)


func _setup_camera() -> void:
	var camera := player.camera
	if camera == null:
		return
	camera.limit_left = int(map_bounds.position.x)
	camera.limit_top = int(map_bounds.position.y)
	camera.limit_right = int(map_bounds.end.x)
	camera.limit_bottom = int(map_bounds.end.y)


func _place_player() -> void:
	var target := spawn_point
	# Posisi dari save (bila ada) lebih diprioritaskan.
	if typeof(GameManager.pending_player_position) == TYPE_VECTOR2:
		target = GameManager.pending_player_position
		GameManager.pending_player_position = null
	player.teleport_to(target)


func _ensure_quest() -> void:
	if not QuestManager.has_started("q_pulang") and not QuestManager.is_completed("q_tapak"):
		QuestManager.start_quest("q_pulang")
		GameManager.show_banner("Desa Arunika", "Setiap langkah meninggalkan cerita")


func _apply_world_state() -> void:
	var event_ready := GameManager.get_flag("event_ready")
	for child in entities.get_children():
		if child is Prop:
			var prop: Prop = child
			if prop.kind == "lamp" or prop.kind == "fire_pit":
				prop.glow = 1.0 if event_ready else 0.0
	if event_ready:
		_gather_villagers()
		_create_firefly_particles()


func _gather_villagers() -> void:
	for child in entities.get_children():
		if child is Npc:
			var npc: Npc = child
			npc.apply_gather_position()


func _on_flag_changed(flag: String, value: Variant) -> void:
	if flag == "event_ready" and bool(value):
		_apply_world_state()
		GameManager.show_banner("Lapangan Guyub", "Warga mulai berkumpul")


func _create_leaf_particles() -> void:
	if _ambient_created:
		return
	_ambient_created = true
	var leaf_texture := TextureFactory.leaf(18, 11, Palette.LEAF)
	var emitter := SparkleFx.ambient_particles(
		entities,
		Vector2(map_bounds.size.x * 0.5, map_bounds.size.y * 0.25),
		Vector2(map_bounds.size.x * 0.9, map_bounds.size.y * 0.5),
		Palette.with_alpha(Palette.LEAF_LIGHT, 0.85),
		14,
		leaf_texture,
		22.0,
		9.0
	)
	emitter.z_index = 120


func _create_firefly_particles() -> void:
	if entities.has_node("Fireflies"):
		return
	var fireflies := SparkleFx.ambient_particles(
		entities,
		Vector2(1520, 1180),
		Vector2(1500, 700),
		Palette.with_alpha(Palette.LANTERN, 0.95),
		22,
		TextureFactory.soft_dot(14, 0.15, Palette.LANTERN),
		12.0,
		7.0
	)
	fireflies.name = "Fireflies"
	fireflies.gravity = Vector2(0, -2)
	fireflies.z_index = 150
