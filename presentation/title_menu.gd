# Clowder: Alley Siege - Title & Hub Menu Screen
class_name TitleMenu
extends Control

const SimSaveManager = preload("res://sim/save_manager.gd")
const WoodTheme = preload("res://presentation/wood_theme.gd")

signal play_pressed
signal almanac_pressed
signal insights_pressed
signal shop_pressed
signal prestige_shop_pressed
signal settings_pressed
signal leaderboard_pressed
signal coop_pressed

var level_lbl: Label
var xp_bar: ProgressBar
var fishcoin_lbl: Label
var golden_bones_lbl: Label
var prop_sprites: Dictionary = {}

func setup(save_mgr: SimSaveManager, p_prop_sprites: Dictionary = {}) -> void:
	prop_sprites = p_prop_sprites
	_build_ui()
	update_profile_display(save_mgr)
	queue_redraw()

func _draw() -> void:
	# Illustrated alley backdrop from the Stage 2 prop language
	draw_rect(Rect2(0, 0, size.x, size.y), Color(0.11, 0.08, 0.07, 0.96))
	# Warm twilight horizon band
	draw_rect(Rect2(0, size.y * 0.48, size.x, size.y * 0.52), Color(0.16, 0.11, 0.08, 0.95))
	# Cobble street silhouette along bottom
	draw_rect(Rect2(0, size.y * 0.72, size.x, size.y * 0.28), Color(0.24, 0.17, 0.12))
	draw_line(Vector2(0, size.y * 0.72), Vector2(size.x, size.y * 0.72), Color(0.93, 0.72, 0.32, 0.45), 3.0)

	# Warm lantern glow pools
	draw_circle(Vector2(210, 420), 110, Color(0.96, 0.68, 0.28, 0.12))
	draw_circle(Vector2(size.x - 210, 420), 110, Color(0.96, 0.68, 0.28, 0.12))

	# Stage 2 props flanking the central wood menu column
	_draw_backdrop_prop("stoop", Vector2(140, 500), 180.0)
	_draw_backdrop_prop("awning", Vector2(210, 320), 155.0)
	_draw_backdrop_prop("lantern", Vector2(290, 460), 115.0)
	_draw_backdrop_prop("hanging_wash", Vector2(size.x - 210, 310), 165.0)
	_draw_backdrop_prop("crate_stack", Vector2(size.x - 160, 515), 165.0)
	_draw_backdrop_prop("mouse_hole", Vector2(110, 565), 85.0)
	_draw_backdrop_prop("fish_basket", Vector2(size.x - 105, 575), 82.0)

func _draw_backdrop_prop(id: String, pos: Vector2, height: float) -> void:
	var tex: Texture2D = prop_sprites.get(id)
	if tex == null:
		return
	var sc := height / float(tex.get_height())
	var w := float(tex.get_width()) * sc
	draw_texture_rect(tex, Rect2(pos - Vector2(w * 0.5, height * 0.55), Vector2(w, height)), false, Color(0.92, 0.86, 0.78, 0.88))

func _build_ui() -> void:
	set_anchors_preset(PRESET_FULL_RECT)

	var frame_panel := PanelContainer.new()
	frame_panel.set_anchors_preset(PRESET_CENTER)
	frame_panel.custom_minimum_size = Vector2(500, 610)
	frame_panel.offset_left = -250.0
	frame_panel.offset_top = -305.0
	frame_panel.offset_right = 250.0
	frame_panel.offset_bottom = 305.0
	frame_panel.add_theme_stylebox_override("panel", WoodTheme.panel_style())
	add_child(frame_panel)

	var center_vbox := VBoxContainer.new()
	center_vbox.add_theme_constant_override("separation", 11)
	frame_panel.add_child(center_vbox)

	# Title Banner
	var title_lbl := Label.new()
	title_lbl.text = "CLOWDER"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 42)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	center_vbox.add_child(title_lbl)

	var subtitle_lbl := Label.new()
	subtitle_lbl.text = "Alley Siege — Defense of the Warrens"
	subtitle_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_lbl.add_theme_font_size_override("font_size", 15)
	subtitle_lbl.add_theme_color_override("font_color", Color(0.86, 0.76, 0.62))
	center_vbox.add_child(subtitle_lbl)

	# Profile Status Card
	var profile_panel := PanelContainer.new()
	profile_panel.add_theme_stylebox_override("panel", WoodTheme.card_style(false))
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
	fishcoin_lbl.text = "0 Fishcoin"
	fishcoin_lbl.add_theme_color_override("font_color", Color(0.55, 0.85, 0.98))
	p_top_hbox.add_child(fishcoin_lbl)

	golden_bones_lbl = Label.new()
	golden_bones_lbl.text = "  0 Golden Bones"
	golden_bones_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
	p_top_hbox.add_child(golden_bones_lbl)

	xp_bar = ProgressBar.new()
	xp_bar.custom_minimum_size = Vector2(0, 10)
	xp_bar.show_percentage = false
	p_vbox.add_child(xp_bar)

	center_vbox.add_child(HSeparator.new())

	# Navigation Buttons
	_add_menu_btn(center_vbox, "PLAY — Choose Alley", func():
		visible = false
		play_pressed.emit()
	, Color(0.42, 0.95, 0.48))

	_add_menu_btn(center_vbox, "The Almanac", func():
		almanac_pressed.emit()
	)

	_add_menu_btn(center_vbox, "Insights", func():
		insights_pressed.emit()
	)

	_add_menu_btn(center_vbox, "Alley Shop", func():
		shop_pressed.emit()
	)

	_add_menu_btn(center_vbox, "Collector's Vault", func():
		prestige_shop_pressed.emit()
	, Color(1.0, 0.82, 0.28))

	_add_menu_btn(center_vbox, "Leaderboards", func():
		leaderboard_pressed.emit()
	, Color(1.0, 0.88, 0.45))

	_add_menu_btn(center_vbox, "Co-op Mode", func():
		coop_pressed.emit()
	, Color(0.40, 0.86, 0.96))

	_add_menu_btn(center_vbox, "Settings", func():
		settings_pressed.emit()
	)

func _add_menu_btn(container: VBoxContainer, label_text: String, on_click: Callable, color_override: Color = Color.WHITE) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(400, 40)
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
	fishcoin_lbl.text = "%d Fishcoin" % fish
	golden_bones_lbl.text = "  %d Golden Bones" % bones

	var next_xp = 120 + 30 * lvl
	xp_bar.max_value = next_xp
	xp_bar.value = xp
