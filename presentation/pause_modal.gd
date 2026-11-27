class_name PauseModal
extends PanelContainer

signal resume_pressed
signal settings_pressed
signal almanac_pressed
signal insights_pressed
signal shop_pressed
signal vault_pressed
signal leaderboard_pressed
signal coop_pressed
signal title_pressed

var controls_lbl: Label

func setup() -> void:
	_build_ui()

func _build_ui() -> void:
	custom_minimum_size = Vector2(460, 480)
	offset_left = 410.0
	offset_top = 110.0
	offset_right = 870.0
	offset_bottom = 590.0

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	add_child(vbox)

	var title := Label.new()
	title.text = "Match Paused"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	var resume_btn := Button.new()
	resume_btn.text = "Resume Match"
	resume_btn.custom_minimum_size = Vector2(0, 42)
	resume_btn.add_theme_color_override("font_color", Color(0.45, 0.96, 0.48))
	resume_btn.pressed.connect(func(): resume_pressed.emit())
	vbox.add_child(resume_btn)

	var settings_btn := Button.new()
	settings_btn.text = "Settings"
	settings_btn.custom_minimum_size = Vector2(0, 38)
	settings_btn.pressed.connect(func(): settings_pressed.emit())
	vbox.add_child(settings_btn)

	vbox.add_child(HSeparator.new())

	var den_lbl := Label.new()
	den_lbl.text = "The Den"
	den_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	den_lbl.add_theme_font_size_override("font_size", 14)
	vbox.add_child(den_lbl)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	vbox.add_child(grid)

	for item in [
		{"text": "Almanac", "sig": almanac_pressed},
		{"text": "Insights", "sig": insights_pressed},
		{"text": "Alley Shop", "sig": shop_pressed},
		{"text": "Collector's Vault", "sig": vault_pressed},
		{"text": "Leaderboards", "sig": leaderboard_pressed},
		{"text": "Co-op", "sig": coop_pressed}
	]:
		var b := Button.new()
		b.text = item["text"]
		b.custom_minimum_size = Vector2(0, 34)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var s: Signal = item["sig"]
		b.pressed.connect(func(): s.emit())
		grid.add_child(b)

	controls_lbl = Label.new()
	controls_lbl.text = "Keys: Space send | 1 / 2 / 3 speed | Esc pause | 1 / 2 / 3 open feat card"
	controls_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_lbl.add_theme_font_size_override("font_size", 12)
	controls_lbl.add_theme_color_override("font_color", Color(0.84, 0.78, 0.68))
	controls_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(controls_lbl)

	vbox.add_child(HSeparator.new())

	var title_btn := Button.new()
	title_btn.text = "Return to Title"
	title_btn.custom_minimum_size = Vector2(0, 38)
	title_btn.add_theme_color_override("font_color", Color(1.0, 0.56, 0.44))
	title_btn.pressed.connect(func(): title_pressed.emit())
	vbox.add_child(title_btn)
