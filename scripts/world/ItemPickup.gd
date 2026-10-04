class_name ItemPickup
extends Interactable
## Barang yang bisa diambil dari dunia (bambu, dsb).
##
## Setelah diambil, sebuah flag disimpan supaya barang tidak muncul lagi saat
## permainan dimuat kembali.

@export var item_id := ""
@export var amount := 1
## Opsional: langsung menambah progres quest saat diambil.
@export var quest_id := ""
@export var objective_id := ""
## Flag penanda "sudah diambil". Bila kosong, dipakai "took_<item_id>".
@export var flag_id := ""
@export var sparkle_color: Color = Palette.GOLD


func _ready() -> void:
	super._ready()
	prompt_icon = "grab"
	if prompt_text == "Berinteraksi":
		prompt_text = "Ambil " + Inventory.display_name(item_id)
	if not flag_id.is_empty() and GameManager.has_flag(flag_id):
		queue_free()
		return
	var icon := get_node_or_null("Icon")
	if icon != null and icon.has_method("setup"):
		icon.call("setup", str(Inventory.entry(item_id).get("icon", "bambu")), sparkle_color)


func can_interact() -> bool:
	return enabled and GameManager.can_player_act()


func interact() -> void:
	if not can_interact():
		return
	var flag := flag_id if not flag_id.is_empty() else "took_" + item_id
	GameManager.add_item(item_id, amount)
	if not quest_id.is_empty() and not objective_id.is_empty():
		QuestManager.advance_objective(quest_id, objective_id, amount)
	GameManager.set_flag(flag, true)
	GameManager.audio.play_sfx("pickup", -3.0)
	interacted.emit(self)
	var parent := get_parent()
	if parent != null:
		SparkleFx.burst(parent, global_position + Vector2(0, -20), sparkle_color, 16, 20.0)
		SparkleFx.ring_pop(parent, global_position + Vector2(0, -20), sparkle_color, 40.0)
	queue_free()
