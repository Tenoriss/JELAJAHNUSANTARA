class_name QuestPanel
extends OverlayPanel
## Jurnal perjalanan: tujuan yang sedang berjalan dan yang sudah selesai.


func _build() -> void:
	UiKit.clear(list)
	var active := QuestManager.get_active_quests()
	var completed := QuestManager.get_completed_quests()
	if active.is_empty() and completed.is_empty():
		add_empty_state("Belum ada tujuan. Bicaralah dengan warga desa.")
		return
	if not active.is_empty():
		add_heading("Sedang Berjalan")
		for quest in active:
			_add_quest(quest, true)
	if not completed.is_empty():
		add_gap(14.0)
		add_heading("Selesai", Palette.HINT)
		for quest in completed:
			_add_quest(quest, false)


func _add_quest(quest: Quest, show_objectives: bool) -> void:
	var holder := UiKit.panel(Palette.with_alpha(Palette.INK, 0.55), 10)
	var column := UiKit.column(6)
	column.add_child(UiKit.label("•  " + quest.title, 21, Palette.GOLD if show_objectives else Palette.HINT))
	if not quest.description.is_empty():
		column.add_child(UiKit.wrapped_label(quest.description, 16, Palette.CREAM_DIM))
	if show_objectives:
		for objective in quest.objectives:
			var done: bool = int(objective["progress"]) >= int(objective["required"])
			var text := str(objective["text"])
			if int(objective["required"]) > 1:
				text += "  (%d/%d)" % [int(objective["progress"]), int(objective["required"])]
			column.add_child(
				UiKit.label(
					("      ✓  " if done else "      ○  ") + text,
					16,
					Palette.HINT if done else Palette.CREAM
				)
			)
	holder.add_child(column)
	list.add_child(holder)
