class_name OverlayPanel
extends Control
## Dasar panel layar penuh yang bisa dibuka dan ditutup (jurnal, inventaris,
## catatan budaya, pengaturan).
##
## Isi panel dibangun ulang setiap kali dibuka supaya selalu mengikuti keadaan
## permainan terbaru.

signal closed()

@export var panel_title := "Panel"

@onready var title_label: Label = $Center/Panel/VBox/Header/Title
@onready var close_button: Button = $Center/Panel/VBox/Header/CloseButton
@onready var list: VBoxContainer = $Center/Panel/VBox/Scroll/List


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	title_label.text = panel_title
	close_button.pressed.connect(_on_close_pressed)
	visible = false


func open() -> void:
	_build()
	visible = true
	close_button.grab_focus()


func close() -> void:
	visible = false


func is_open() -> bool:
	return visible


func _on_close_pressed() -> void:
	GameManager.audio.play_ui_click()
	closed.emit()


# --- Bagian yang diisi kelas turunan --------------------------------------

func _build() -> void:
	pass


# --- Pembantu tata letak --------------------------------------------------

func add_heading(text: String, color: Color = Palette.GOLD) -> void:
	list.add_child(UiKit.label(text, 20, color))


func add_paragraph(text: String, color: Color = Palette.CREAM_DIM) -> void:
	list.add_child(UiKit.wrapped_label(text, 17, color))


func add_empty_state(text: String) -> void:
	list.add_child(UiKit.label(text, 17, Palette.CREAM_DARK))


func add_gap(height := 12.0) -> void:
	list.add_child(UiKit.spacer(0.0, height))
