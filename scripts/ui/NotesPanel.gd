class_name NotesPanel
extends OverlayPanel
## Catatan budaya: rangkuman hal yang sudah ditemui pemain di desa.
##
## Pembelajaran disampaikan lewat dialog, papan informasi, dan benda di dunia —
## panel ini hanya mengingatkan kembali apa yang sudah ditemukan.


func _build() -> void:
	UiKit.clear(list)
	var found := GameManager.notes_found
	add_paragraph(
		"Catatan terkumpul: %d dari %d. Temukan papan informasi dan obrolan warga untuk menambahnya."
		% [found.size(), GameManager.notes_data.size()],
		Palette.CREAM_DARK
	)
	add_gap(10.0)
	if found.is_empty():
		add_empty_state("Belum ada catatan yang ditemukan.")
		return
	for note_id in found:
		_add_note(note_id)


func _add_note(note_id: String) -> void:
	var holder := UiKit.panel(Palette.with_alpha(Palette.INK, 0.55), 10)
	var column := UiKit.column(4)
	column.add_child(UiKit.label(GameManager.note_title(note_id), 20, Palette.GOLD_PALE))
	column.add_child(UiKit.wrapped_label(GameManager.note_text(note_id), 16, Palette.CREAM))
	holder.add_child(column)
	list.add_child(holder)
