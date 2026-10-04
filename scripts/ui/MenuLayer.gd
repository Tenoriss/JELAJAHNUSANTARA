class_name MenuLayer
extends CanvasLayer
## Lapisan menu dalam permainan: menu jeda, jurnal quest, inventaris, catatan
## budaya, dan pengaturan. Hanya satu panel yang tampil pada satu waktu.

@onready var root: Control = $Root
@onready var pause_menu: PauseMenu = $Root/PauseMenu
@onready var quest_panel: QuestPanel = $Root/QuestPanel
@onready var inventory_panel: InventoryPanel = $Root/InventoryPanel
@onready var notes_panel: NotesPanel = $Root/NotesPanel
@onready var settings_panel: SettingsPanel = $Root/SettingsPanel

var _from_pause := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	root.visible = false
	pause_menu.resume_requested.connect(close_all)
	pause_menu.panel_requested.connect(_on_panel_requested)
	pause_menu.save_requested.connect(_on_save_requested)
	pause_menu.menu_requested.connect(_on_menu_requested)
	for panel in panels():
		panel.closed.connect(_on_panel_closed)


func panels() -> Array[OverlayPanel]:
	var result: Array[OverlayPanel] = []
	result.append(quest_panel)
	result.append(inventory_panel)
	result.append(notes_panel)
	result.append(settings_panel)
	return result


func is_open() -> bool:
	return root.visible


# --- Membuka ---------------------------------------------------------------

func open_pause() -> void:
	if not GameManager.game_started:
		return
	_from_pause = true
	_hide_panels()
	root.visible = true
	pause_menu.visible = true
	GameManager.set_paused(true)
	pause_menu.focus_first()


func open_quests() -> void:
	_open_panel(quest_panel, false)


func open_inventory() -> void:
	_open_panel(inventory_panel, false)


func open_notes() -> void:
	_open_panel(notes_panel, false)


func _open_panel(panel: OverlayPanel, from_pause: bool) -> void:
	if not GameManager.game_started:
		return
	_from_pause = from_pause
	_hide_panels()
	root.visible = true
	panel.open()
	GameManager.set_paused(true)


func close_all() -> void:
	_hide_panels()
	root.visible = false
	GameManager.set_paused(false)


## Dipanggil saat ESC ditekan ketika menu sedang terbuka.
func back() -> void:
	if _from_pause and not pause_menu.visible:
		_hide_panels()
		pause_menu.visible = true
		pause_menu.focus_first()
		return
	close_all()


func _hide_panels() -> void:
	for panel in panels():
		panel.close()
	pause_menu.visible = false


# --- Tombol ---------------------------------------------------------------

func _on_panel_requested(panel_id: String) -> void:
	match panel_id:
		"quests":
			_open_panel(quest_panel, true)
		"inventory":
			_open_panel(inventory_panel, true)
		"notes":
			_open_panel(notes_panel, true)
		"settings":
			_open_panel(settings_panel, true)


func _on_panel_closed() -> void:
	if _from_pause:
		back()
	else:
		close_all()


func _on_save_requested() -> void:
	var saved := SaveManager.save_game()
	GameManager.show_toast(
		"Permainan tersimpan" if saved else "Gagal menyimpan permainan",
		Palette.HINT if saved else Palette.DANGER
	)


func _on_menu_requested() -> void:
	close_all()
	GameManager.return_to_main_menu()
