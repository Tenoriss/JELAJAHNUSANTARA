class_name SupplyStation
extends Interactable
## Stasiun persiapan di Lapangan Guyub: pintu masuk Puzzle 2.
##
## Bila semua perlengkapan sudah dibawa, puzzle persiapan dibuka. Bila belum,
## pemain diberi tahu barang apa saja yang masih kurang.

@export var required_items: PackedStringArray = PackedStringArray(["bambu", "tali", "papan_kayu", "kain_pola"])
@export var puzzle_id := "prep"
@export var ready_dialogue := "panggung"
## Dialog saat perlengkapan belum lengkap (lihat data/dialogue/event.json).
@export var missing_dialogue := "persiapan_kurang"


func _ready() -> void:
	super._ready()
	prompt_icon = "build"
	if prompt_text == "Berinteraksi":
		prompt_text = "Susun perlengkapan"


func interact() -> void:
	if not can_interact():
		return
	interacted.emit(self)
	if GameManager.get_flag("puzzle_" + puzzle_id + "_done"):
		DialogueManager.start(ready_dialogue)
		return
	var missing := GameManager.inventory.missing(required_items)
	if missing.is_empty():
		GameManager.start_puzzle(puzzle_id)
		return
	# Daftar kekurangan ditampilkan sebagai toast supaya pemain tahu persis
	# barang apa yang masih dicari, sementara Sari memberi petunjuk arah.
	GameManager.show_toast("Masih kurang: " + _missing_label(missing), Palette.GOLD_PALE)
	DialogueManager.start(missing_dialogue)


func _missing_label(ids: Array) -> String:
	var names := PackedStringArray()
	for id in ids:
		names.append(Inventory.display_name(str(id)))
	return ", ".join(names)
