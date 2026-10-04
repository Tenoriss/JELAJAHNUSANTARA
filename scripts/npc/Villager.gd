class_name Villager
extends Npc
## Warga latar yang berjalan sepanjang jalur desa supaya desa terasa hidup.
##
## Mereka tetap bisa diajak bicara dengan satu-dua baris singkat ("bark").


func _ready() -> void:
	super._ready()
	wander_speed = maxf(wander_speed, 22.0)
	wander_pause = randf_range(1.2, 2.6)
	# Variasi kecil supaya langkah warga tidak seragam.
	_wander_timer = randf_range(0.0, 1.4)
