class_name AreaZone
extends Area2D
## Pemicu wilayah: menampilkan nama area saat pemain masuk.

@export var area_title := ""
@export var area_subtitle := ""
@export var once := true
@export var flag_id := ""
## Ukuran area pemicu (diubah per instance lewat Inspector).
@export var zone_size := Vector2(400, 300):
	set(value):
		zone_size = value
		_apply_size()


func _ready() -> void:
	_apply_size()
	body_entered.connect(_on_body_entered)
	if once and not flag_id.is_empty() and GameManager.has_flag(flag_id):
		monitoring = false


func _apply_size() -> void:
	var shape_node := get_node_or_null("Shape") as CollisionShape2D
	if shape_node == null:
		return
	# Shape baru per area supaya setiap zona punya ukuran sendiri.
	var rect := RectangleShape2D.new()
	rect.size = zone_size
	shape_node.shape = rect


func _on_body_entered(body: Node2D) -> void:
	if not (body is Player):
		return
	if once and not flag_id.is_empty():
		if GameManager.has_flag(flag_id):
			return
		GameManager.set_flag(flag_id, true)
	GameManager.show_banner(area_title, area_subtitle)
	GameManager.audio.play_sfx("hover", -10.0)
