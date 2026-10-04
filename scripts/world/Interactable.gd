class_name Interactable
extends Area2D
## Dasar semua objek yang bisa diinteraksi: NPC, barang, papan, stasiun puzzle.
##
## PlayerInteractor memanggil set_focused() ketika objek berada paling dekat
## dengan pemain, dan interact() ketika tombol interaksi ditekan.

signal interacted(source: Interactable)

@export var prompt_text := "Berinteraksi"
@export var prompt_icon := "talk"  # talk | grab | read | build
@export var enabled := true

var focused := false

var _prompt: Node2D = null


func _ready() -> void:
	_prompt = get_node_or_null("Prompt")
	if _prompt != null:
		_prompt.visible = false
		if _prompt.has_method("configure"):
			_prompt.call("configure", self)


## Teks yang ditampilkan pada balon interaksi.
func get_prompt_text() -> String:
	return prompt_text


func get_prompt_icon() -> String:
	return prompt_icon


## Boleh diinteraksi sekarang? (keadaan game, progres cerita, dsb.)
func can_interact() -> bool:
	return enabled and GameManager.can_player_act()


func set_focused(value: bool) -> void:
	var should_focus := value and can_interact()
	if should_focus == focused:
		return
	focused = should_focus
	if _prompt != null:
		_prompt.visible = should_focus
		if should_focus and _prompt.has_method("pop_in"):
			_prompt.call("pop_in")


## Aksi default: cukup memancarkan sinyal. Subclass menimpa fungsi ini.
func interact() -> void:
	interacted.emit(self)
