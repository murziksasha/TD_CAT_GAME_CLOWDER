# Clowder: Alley Siege - Title & Hub Menu Screen
class_name TitleMenu
extends Control

const SimSaveManager = preload("res://sim/save_manager.gd")

signal play_pressed
signal almanac_pressed
signal insights_pressed
signal shop_pressed
signal prestige_shop_pressed
signal settings_pressed
signal leaderboard_pressed

var level_lbl: Label
var xp_bar: ProgressBar
var fishcoin_lbl: Label
var golden_bones_lbl: Label

func setup(save_mgr: SimSaveManager) -> void:
	_build_ui()
	update_profile_display(save_mgr)

func _build_ui() -> void:
	set_anchors_preset(PRESET_FULL_RECT)

	# Cozy dark storybook vignette background
	var bg_panel := Panel.new()
	bg_panel.set_anchors_preset(PRESET_FULL_RECT)
	var bg_box := StyleBoxFlat.new()
	bg_box.bg_color = Color(0.12, 0.08, 0.06, 0.94)
	bg_panel.add_theme_stylebox_override("panel", bg_box)
	add_child(bg_panel)

	var center_vbox := VBoxContainer.new()
	center_vbox.set_anchors_preset(PRESET_CENTER)
	center_vbox.custom_minimum_size = Vector2(480, 560)
	center_vbox.offset_left = -240.0
	center_vbox.offset_top = -280.0
	center_vbox.offset_right = 240.0
	center_vbox.offset_bottom = 280.0
	center_vbox.add_theme_constant_override("separation", 14)
	add_child(center_vbox)

	# Title Banner
	var title_lbl := Label.new()
	title_lbl.text = "🐾 CLOWDER 🐾"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 44)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	center_vbox.add_child(title_lbl)

	var subtitle_lbl := Label.new()
	subtitle_lbl.text = "Alley Siege — Defense of the Warrens"
	subtitle_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_lbl.add_theme_font_size_override("font_size", 16)
	subtitle_lbl.add_theme_color_override("font_color", Color(0.85, 0.72, 0.58))
	center_vbox.add_child(subtitle_lbl)

	# Profile Status Card
	var profile_panel := PanelContainer.new()
	center_vbox.add_child(profile_panel)

	var p_vbox := VBoxContainer.new()
	p_vbox.add_theme_constant_override("separation", 6)
	profile_panel.add_child(p_vbox)

	var p_top_hbox := HBoxContainer.new()
	p_vbox.add_child(p_top_hbox)

	level_lbl = Label.new()
	level_lbl.text = "Account Level 1"
	level_lbl.add_theme_font_size_override("font_size", 15)
	level_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
	level_lbl.size_flags_horizontal = SIZE_EXPAND_FILL
	p_top_hbox.add_child(level_lbl)

	fishcoin_lbl = Label.new()
	fishcoin_lbl.text = "🐟 0 Fishcoin"
	fishcoin_lbl.add_theme_color_override("font_color", Color(0.5, 0.85, 1.0))
	p_top_hbox.add_child(fishcoin_lbl)

	golden_bones_lbl = Label.new()
	golden_bones_lbl.text = "  🦴 0 Golden Bones"
	golden_bones_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	p_top_hbox.add_child(golden_bones_lbl)

	xp_bar = ProgressBar.new()
	xp_bar.custom_minimum_size = Vector2(0, 10)
	xp_bar.show_percentage = false
	p_vbox.add_child(xp_bar)

	center_vbox.add_child(HSeparator.new())

	# Navigation Buttons
	_add_menu_btn(center_vbox, "⚔ PLAY — Defend the Alley", func():
		visible = false
		play_pressed.emit()
	, Color(0.4, 0.95, 0.45))

	_add_menu_btn(center_vbox, "📖 The Almanac (Encyclopedia)", func():
		almanac_pressed.emit()
	)

	_add_menu_btn(center_vbox, "🔮 Insights (Passive Trees)", func():
		insights_pressed.emit()
	)

	_add_menu_btn(center_vbox, "🐟 Alley Shop (Tricks & Looks)", func():
		shop_pressed.emit()
	)

	_add_menu_btn(center_vbox, "🦴 Collector's Vault (Super Shop)", func():
		prestige_shop_pressed.emit()
	, Color(1.0, 0.82, 0.25))

	_add_menu_btn(center_vbox, "🏆 Top 100 Leaderboards", func():
		leaderboard_pressed.emit()
	, Color(1.0, 0.88, 0.45))

	_add_menu_btn(center_vbox, "⚙ Settings & Accessibility", func():
		settings_pressed.emit()
	)

func _add_menu_btn(container: VBoxContainer, label_text: String, on_click: Callable, color_override: Color = Color.WHITE) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(400, 44)
	btn.pressed.connect(on_click)
	if color_override != Color.WHITE:
		btn.add_theme_color_override("font_color", color_override)
	container.add_child(btn)
	return btn

func update_profile_display(save_mgr: SimSaveManager) -> void:
	if save_mgr == null or level_lbl == null:
		return
	var acc: Dictionary = save_mgr.data.get("account", {})
	var eco: Dictionary = save_mgr.data.get("economy", {})

	var lvl = int(acc.get("level", 1))
	var xp = int(acc.get("xp", 0))
	var fish = int(eco.get("fishcoin", 0))
	var bones = int(eco.get("golden_bones", 0))

	level_lbl.text = "Account Level %d" % lvl
	fishcoin_lbl.text = "🐟 %d Fishcoin" % fish
	golden_bones_lbl.text = "  🦴 %d Golden Bones" % bones

	var next_xp = 120 + 30 * lvl
	xp_bar.max_value = next_xp
	xp_bar.value = xp
