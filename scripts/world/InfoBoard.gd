class_name InfoBoard
extends Interactable
## Papan, sumur, prasasti, dan objek lain yang bisa dibaca.
##
## Membaca objek seperti ini adalah cara utama pemain menemukan Catatan Budaya
## (lihat data/notes/cultural_notes.json).

@export var dialogue_id := ""
@export var note_id := ""


func _ready() -> void:
	super._ready()
	prompt_icon = "read"
	if prompt_text == "Berinteraksi":
		prompt_text = "Baca"


func interact() -> void:
	if not can_interact():
		return
	if not note_id.is_empty():
		GameManager.find_note(note_id)
	if not dialogue_id.is_empty():
		DialogueManager.start(dialogue_id)
	interacted.emit(self)
