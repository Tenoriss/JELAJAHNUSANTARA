class_name PauseMenu
extends Control
## Menu jeda: lanjut, quest, inventaris, catatan, simpan, pengaturan, menu.

signal resume_requested()
signal panel_requested(panel_id: String)
signal save_requested()
signal menu_requested()

@onready var resume_button: Button = $Center/Panel/VBox/ResumeButton
@onready var quest_button: Button = $Center/Panel/VBox/QuestButton
@onready var inventory_button: Button = $Center/Panel/VBox/InventoryButton
@onready var notes_button: Button = $Center/Panel/VBox/NotesButton
@onready var save_button: Button = $Center/Panel/VBox/SaveButton
@onready var settings_button: Button = $Center/Panel/VBox/SettingsButton
@onready var menu_button: Button = $Center/Panel/VBox/MenuButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	resume_button.pressed.connect(_on_resume_pressed)
	quest_button.pressed.connect(_on_panel_pressed.bind("quests"))
	inventory_button.pressed.connect(_on_panel_pressed.bind("inventory"))
	notes_button.pressed.connect(_on_panel_pressed.bind("notes"))
	save_button.pressed.connect(_on_save_pressed)
	settings_button.pressed.connect(_on_panel_pressed.bind("settings"))
	menu_button.pressed.connect(_on_menu_pressed)
	for button in [
		resume_button, quest_button, inventory_button, notes_button, save_button, settings_button, menu_button
	]:
		button.mouse_entered.connect(_on_hover)


func focus_first() -> void:
	resume_button.grab_focus()


func _on_resume_pressed() -> void:
	GameManager.audio.play_ui_click()
	resume_requested.emit()


func _on_panel_pressed(panel_id: String) -> void:
	GameManager.audio.play_ui_click()
	panel_requested.emit(panel_id)


func _on_save_pressed() -> void:
	GameManager.audio.play_ui_click()
	save_requested.emit()


func _on_menu_pressed() -> void:
	GameManager.audio.play_ui_click()
	menu_requested.emit()


func _on_hover() -> void:
	GameManager.audio.play_sfx("hover", -16.0)
