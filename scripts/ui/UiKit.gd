class_name UiKit
extends RefCounted
## Perkakas kecil untuk menyusun antarmuka dari kode.
##
## Dipakai bersama oleh HUD, dialog, panel, dan menu supaya gaya visualnya
## konsisten tanpa mengulang kode yang sama.


static func label(text: String, size := 18, color: Color = Palette.CREAM) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


static func wrapped_label(text: String, size := 18, color: Color = Palette.CREAM) -> Label:
	var node := label(text, size, color)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return node


static func title(text: String, size := 30) -> Label:
	var node := label(text, size, Palette.GOLD)
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return node


static func subtitle(text: String, size := 17) -> Label:
	var node := label(text, size, Palette.CREAM_DIM)
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return node


static func button(text: String, size := 20) -> Button:
	var node := Button.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	node.focus_mode = Control.FOCUS_ALL
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return node


static func spacer(width := 0.0, height := 0.0) -> Control:
	var node := Control.new()
	node.custom_minimum_size = Vector2(width, height)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


static func row(separation := 10) -> HBoxContainer:
	var node := HBoxContainer.new()
	node.add_theme_constant_override("separation", separation)
	return node


static func column(separation := 8) -> VBoxContainer:
	var node := VBoxContainer.new()
	node.add_theme_constant_override("separation", separation)
	return node


static func panel(bg: Color = Palette.INK_SOFT, radius := 14) -> PanelContainer:
	var node := PanelContainer.new()
	node.add_theme_stylebox_override("panel", DrawKit.box_style(bg, radius, Palette.with_alpha(Palette.GOLD, 0.35), 2))
	return node


## Latar gelap transparan untuk menu yang menutupi layar.
static func dim(alpha := 0.72) -> ColorRect:
	var node := ColorRect.new()
	node.color = Color(Palette.INK.r, Palette.INK.g, Palette.INK.b, alpha)
	node.mouse_filter = Control.MOUSE_FILTER_STOP
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return node


static func clear(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()
		container.remove_child(child)


static func color_from(value: Variant, fallback: Color) -> Color:
	if typeof(value) == TYPE_STRING and not str(value).is_empty():
		return Color.from_string(str(value), fallback)
	if typeof(value) == TYPE_COLOR:
		return value
	return fallback
