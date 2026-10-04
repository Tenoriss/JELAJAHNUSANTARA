class_name SparkleFx
extends RefCounted
## Efek visual sederhana: kilau partikel dan cincin cahaya.
##
## Semua node dibuat saat dibutuhkan lalu menghapus dirinya sendiri, jadi tidak
## ada node efek yang menumpuk di scene.

static func burst(
	parent: Node,
	position: Vector2,
	color: Color = Palette.GOLD,
	count := 14,
	radius := 24.0,
	lifetime := 0.7
) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var particles := CPUParticles2D.new()
	particles.amount = count
	particles.lifetime = lifetime
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = radius * 0.5
	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.gravity = Vector2(0, 70.0)
	particles.initial_velocity_min = 30.0
	particles.initial_velocity_max = 95.0
	particles.scale_amount_min = 0.35
	particles.scale_amount_max = 0.9
	particles.color = color
	particles.texture = TextureFactory.soft_dot(16, 0.3, Color(1, 1, 1, 1))
	particles.position = position
	particles.z_index = 500
	particles.emitting = true
	parent.add_child(particles)
	_autofree(particles, lifetime + 0.8)


## Cincin yang membesar dan memudar — dipakai saat puzzle berhasil.
static func ring_pop(parent: Node, position: Vector2, color: Color = Palette.GOLD, size := 48.0) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var sprite := Sprite2D.new()
	sprite.texture = TextureFactory.ring(64, 0.16, Color(1, 1, 1, 1))
	sprite.modulate = color
	sprite.position = position
	sprite.z_index = 501
	sprite.scale = Vector2(0.2, 0.2)
	parent.add_child(sprite)
	var tween := sprite.create_tween()
	tween.set_parallel(true)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(sprite, "scale", Vector2(size / 64.0, size / 64.0), 0.5)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
	tween.chain().tween_callback(sprite.queue_free)


## Partikel lingkungan yang terus-menerus (daun jatuh, kunang-kunang, debu).
static func ambient_particles(
	parent: Node,
	position: Vector2,
	area: Vector2,
	color: Color,
	amount := 12,
	texture: Texture2D = null,
	velocity := 18.0,
	lifetime := 6.0
) -> CPUParticles2D:
	var particles := CPUParticles2D.new()
	particles.amount = amount
	particles.lifetime = lifetime
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = area * 0.5
	particles.direction = Vector2(0, 1)
	particles.spread = 30.0
	particles.gravity = Vector2(6, 8)
	particles.initial_velocity_min = velocity * 0.4
	particles.initial_velocity_max = velocity
	particles.scale_amount_min = 0.4
	particles.scale_amount_max = 1.0
	particles.color = color
	particles.texture = texture if texture != null else TextureFactory.soft_dot(12, 0.4, Color(1, 1, 1, 1))
	particles.position = position
	particles.z_index = 200
	particles.emitting = true
	parent.add_child(particles)
	return particles


static func _autofree(node: Node, delay: float) -> void:
	var tree := node.get_tree()
	if tree == null:
		return
	var timer := tree.create_timer(delay)
	timer.timeout.connect(
		func() -> void:
			if is_instance_valid(node):
				node.queue_free()
	)
