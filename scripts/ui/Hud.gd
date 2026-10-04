class_name Hud
extends CanvasLayer
## Antarmuka saat bermain: pelacak quest, pemberitahuan, spanduk nama area,
## penghitung catatan budaya, dan pengingat tombol.

const TOAST_LIFETIME := 2.8
const MAX_TOASTS := 4

@onready var root: Control = $Root
@onready var quest_box: PanelContainer = $Root/QuestTracker
@onready var quest_title: Label = $Root/QuestTracker/VBox/QuestTitle
@onready var objective_list: VBoxContainer = $Root/QuestTracker/VBox/Objectives
@onready var counter_label: Label = $Root/Counter/CounterLabel
@onready var hint: Label = $Root/Hint
@onready var toasts: VBoxContainer = $Root/Toasts
@onready var banner_box: VBoxContainer = $Root/Banner
@onready var item_toasts: VBoxContainer = $Root/ItemToasts

var _banner_tween: Tween
var _current_banner: Control = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager.register_hud(self)
	GameManager.toast_requested.connect(_on_toast_requested)
	GameManager.banner_requested.connect(_on_banner_requested)
	GameManager.note_found.connect(_on_note_found)
	QuestManager.quest_started.connect(_on_quest_changed)
	QuestManager.quest_completed.connect(_on_quest_changed)
	QuestManager.objective_completed.connect(_on_objective_completed)
	QuestManager.quest_updated.connect(_on_quest_changed)
	hint.text = "WASD bergerak   ·   E interaksi   ·   Q jurnal   ·   ESC jeda"
	set_hud_visible(false)
	refresh()


func set_hud_visible(value: bool) -> void:
	root.visible = value
	if value:
		refresh()


# --- Pelacak quest --------------------------------------------------------

func refresh() -> void:
	var quest := QuestManager.get_current()
	if quest == null:
		quest_box.visible = false
	else:
		quest_box.visible = true
		quest_title.text = quest.title
		_build_objectives(quest)
	counter_label.text = _counter_text()


func _build_objectives(quest: Quest) -> void:
	UiKit.clear(objective_list)
	for objective in quest.objectives:
		var done: bool = int(objective["progress"]) >= int(objective["required"])
		var text := str(objective["text"])
		if int(objective["required"]) > 1:
			text += " (%d/%d)" % [int(objective["progress"]), int(objective["required"])]
		var line := UiKit.wrapped_label(("✓ " if done else "• ") + text, 16, Palette.HINT if done else Palette.CREAM)
		line.custom_minimum_size.x = 260.0
		objective_list.add_child(line)


func _counter_text() -> String:
	var notes := GameManager.notes_found.size()
	var total_notes := GameManager.notes_data.size()
	var quests_done := QuestManager.get_completed_quests().size()
	return "Catatan budaya %d/%d   ·   Tujuan selesai %d" % [notes, total_notes, quests_done]


# --- Pemberitahuan --------------------------------------------------------

func _on_toast_requested(text: String, color: Color) -> void:
	_show_toast(text, color)


func _show_toast(text: String, color: Color) -> void:
	var holder := UiKit.panel(Palette.with_alpha(Palette.INK, 0.86), 10)
	var label := UiKit.label(text, 17, color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	holder.add_child(label)
	toasts.add_child(holder)
	while toasts.get_child_count() > MAX_TOASTS:
		var oldest := toasts.get_child(0)
		toasts.remove_child(oldest)
		oldest.queue_free()
	_fade_away(holder, TOAST_LIFETIME)


func show_item_toast(item_id: String, amount: int) -> void:
	if not root.visible:
		return
	var holder := UiKit.panel(Palette.with_alpha(Palette.INK, 0.9), 10)
	var row := UiKit.row(10)
	var dot := TextureRect.new()
	dot.texture = TextureFactory.soft_dot(28, 0.25, Inventory.item_color(item_id))
	dot.custom_minimum_size = Vector2(28, 28)
	dot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(dot)
	var text: String = Inventory.display_name(item_id)
	if amount > 1:
		text += "  ×%d" % amount
	var label := UiKit.label(text, 17, Palette.CREAM)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	holder.add_child(row)
	item_toasts.add_child(holder)
	_fade_away(holder, 2.4)


func _fade_away(control: Control, delay: float) -> void:
	control.modulate.a = 0.0
	var tween := control.create_tween()
	tween.tween_property(control, "modulate:a", 1.0, 0.18)
	tween.tween_interval(delay)
	tween.tween_property(control, "modulate:a", 0.0, 0.35)
	tween.tween_callback(control.queue_free)


# --- Spanduk --------------------------------------------------------------

func _on_banner_requested(title: String, subtitle: String) -> void:
	show_banner(title, subtitle)


func show_banner(title: String, subtitle: String) -> void:
	if not root.visible:
		return
	if _current_banner != null and is_instance_valid(_current_banner):
		_current_banner.queue_free()
		UiKit.clear(banner_box)
	var holder := UiKit.panel(Palette.with_alpha(Palette.INK, 0.88), 12)
	var column := UiKit.column(2)
	var title_label := UiKit.title(title, 26)
	column.add_child(title_label)
	if not subtitle.is_empty():
		column.add_child(UiKit.subtitle(subtitle, 16))
	holder.add_child(column)
	banner_box.add_child(holder)
	_current_banner = holder
	holder.modulate.a = 0.0
	var tween := holder.create_tween()
	tween.tween_property(holder, "modulate:a", 1.0, 0.3)
	tween.tween_interval(2.6)
	tween.tween_property(holder, "modulate:a", 0.0, 0.5)
	tween.tween_callback(holder.queue_free)


# --- Sinyal ---------------------------------------------------------------

func _on_quest_changed(_quest: Quest) -> void:
	refresh()


func _on_objective_completed(_quest: Quest, objective: Dictionary) -> void:
	GameManager.audio.play_sfx("place", -6.0)
	refresh()


func _on_note_found(_note_id: String) -> void:
	refresh()
