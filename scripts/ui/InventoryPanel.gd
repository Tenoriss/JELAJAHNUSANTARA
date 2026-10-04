class_name InventoryPanel
extends OverlayPanel
## Inventaris sederhana: hanya barang bawaan yang dipakai untuk quest.


func _build() -> void:
	UiKit.clear(list)
	var items := GameManager.inventory.to_dict()
	if items.is_empty():
		add_empty_state("Belum ada barang yang dibawa.")
		add_gap(8.0)
		add_paragraph("Barang didapat dengan menekan E di dekat benda yang bisa diambil.")
		return
	for item_id in items.keys():
		_add_item(str(item_id), int(items[item_id]))
	add_gap(10.0)
	add_paragraph(
		"Barang bawaan dipakai untuk memperbaiki dan menghias Lapangan Guyub.",
		Palette.CREAM_DARK
	)


func _add_item(item_id: String, amount: int) -> void:
	var holder := UiKit.panel(Palette.with_alpha(Palette.INK, 0.55), 10)
	var row := UiKit.row(16)
	row.add_child(_badge(item_id))
	var column := UiKit.column(2)
	var name_text: String = Inventory.display_name(item_id)
	if amount > 1:
		name_text += "  ×%d" % amount
	column.add_child(UiKit.label(name_text, 20, Palette.GOLD_PALE))
	column.add_child(UiKit.wrapped_label(Inventory.description(item_id), 16, Palette.CREAM_DIM))
	row.add_child(column)
	holder.add_child(row)
	list.add_child(holder)


## Kotak kecil berisi ikon barang yang sama seperti di dunia.
func _badge(item_id: String) -> Control:
	var slot := Panel.new()
	slot.custom_minimum_size = Vector2(58.0, 58.0)
	slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slot.add_theme_stylebox_override(
		"panel",
		DrawKit.box_style(
			Palette.with_alpha(Inventory.item_color(item_id), 0.25),
			10,
			Palette.with_alpha(Palette.GOLD, 0.45),
			2
		)
	)
	var icon := ItemIcon.new()
	icon.setup(str(Inventory.entry(item_id).get("icon", "bambu")), Inventory.item_color(item_id))
	icon.position = Vector2(29.0, 48.0)
	icon.animated = false
	icon.glow = false
	slot.add_child(icon)
	return slot
