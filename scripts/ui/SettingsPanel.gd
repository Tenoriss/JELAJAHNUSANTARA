class_name SettingsPanel
extends OverlayPanel
## Pengaturan audio dan tampilan. Dipakai dari menu utama dan menu jeda.


func _build() -> void:
	UiKit.clear(list)
	_add_slider("Musik", "music")
	_add_slider("Efek suara", "sfx")
	_add_slider("Suara lingkungan", "ambient")
	_add_toggle("Layar penuh", "fullscreen")
	add_gap(12.0)
	add_paragraph(
		"Pengaturan disimpan otomatis dan tidak mengubah simpanan permainan.",
		Palette.CREAM_DARK
	)


func _add_slider(label_text: String, key: String) -> void:
	var column := UiKit.column(4)
	column.add_child(UiKit.label(label_text, 18, Palette.CREAM))
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = float(SaveManager.get_setting(key))
	slider.custom_minimum_size = Vector2(520.0, 28.0)
	slider.value_changed.connect(_on_slider_changed.bind(key))
	column.add_child(slider)
	list.add_child(column)


func _add_toggle(label_text: String, key: String) -> void:
	var check := CheckButton.new()
	check.text = label_text
	check.button_pressed = bool(SaveManager.get_setting(key))
	check.add_theme_font_size_override("font_size", 18)
	check.toggled.connect(_on_toggle_changed.bind(key))
	list.add_child(check)


func _on_slider_changed(value: float, key: String) -> void:
	SaveManager.set_setting(key, value)


func _on_toggle_changed(value: bool, key: String) -> void:
	GameManager.audio.play_ui_click()
	SaveManager.set_setting(key, value)
