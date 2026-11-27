class_name MapSelectModal
extends PanelContainer

const SimConstants = preload("res://sim/constants.gd")
const SimSaveManager = preload("res://sim/save_manager.gd")
const WoodTheme = preload("res://presentation/wood_theme.gd")

signal map_mode_selected(map_id: String, mode: int)
signal closed

const MEDAL_MODES := [
	{"key": "sunny", "label": "S", "name": "Sunny", "col": Color(0.95, 0.78, 0.30)},
	{"key": "alley", "label": "A", "name": "Alley", "col": Color(0.86, 0.58, 0.28)},
	{"key": "night", "label": "N", "name": "Night", "col": Color(0.45, 0.72, 0.88)},
	{"key": "last_whisker", "label": "LW", "name": "Last Whisker", "col": Color(0.92, 0.38, 0.32)},
	{"key": "bare_paw", "label": "BP", "name": "Bare Paw", "col": Color(0.96, 0.92, 0.75)}
]

const MAPS_CATALOG := [
	{"id": "sunny_gutter", "name": "Sunny Gutter", "band": "B"},
	{"id": "lantern_stoop", "name": "Lantern Stoop", "band": "B"},
	{"id": "crabapple_bend", "name": "Crabapple Bend", "band": "B"},
	{"id": "fishbone_straight", "name": "Fishbone Straight", "band": "B"},
	{"id": "morning_arch", "name": "Morning Arch", "band": "B"},
	{"id": "market_lane", "name": "Market Lane", "band": "B+"},
	{"id": "stall_row", "name": "Stall Row", "band": "B+"},
	{"id": "puddle_court", "name": "Puddle Court", "band": "B+"},
	{"id": "sack_corner", "name": "Sack Corner", "band": "B+"},
	{"id": "herring_square", "name": "Herring Square", "band": "B+"},
	{"id": "fig_and_twine", "name": "Fig & Twine", "band": "B+"},
	{"id": "spice_arcade", "name": "Spice Arcade", "band": "B+"},
	{"id": "twin_gutters", "name": "Twin Gutters", "band": "I"},
	{"id": "welcome_bridge", "name": "Welcome Bridge", "band": "I"},
	{"id": "chimney_step", "name": "Chimney Step", "band": "I"},
	{"id": "basket_bridge", "name": "Basket Bridge", "band": "I"},
	{"id": "rooftop_crossing", "name": "Rooftop Crossing", "band": "I"},
	{"id": "copper_scale", "name": "Copper Scale", "band": "I"},
	{"id": "canopy_cross", "name": "Canopy Cross", "band": "I"},
	{"id": "weigh_house", "name": "Weigh House", "band": "I"},
	{"id": "two_purse_lane", "name": "Two-Purse Lane", "band": "A"},
	{"id": "fishmarket_maze", "name": "Fishmarket Maze", "band": "A"},
	{"id": "canal_night", "name": "Canal Night", "band": "A"},
	{"id": "night_onion", "name": "Night Onion", "band": "A"},
	{"id": "grand_bazaar", "name": "Grand Bazaar", "band": "A"},
	{"id": "the_warren", "name": "The Warren", "band": "E"}
]

var save_mgr: SimSaveManager
var selected_mode: int = SimConstants.GameMode.SUNNY
var mode_buttons: Dictionary = {}
var cards_grid: GridContainer
var title_lbl: Label

func setup(p_save_mgr: SimSaveManager) -> void:
	save_mgr = p_save_mgr
	_build_ui()
	refresh()

func _build_ui() -> void:
	custom_minimum_size = Vector2(960, 580)
	offset_left = 160.0
	offset_top = 70.0
	offset_right = 1120.0
	offset_bottom = 650.0

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 10)
	add_child(root_vbox)

	var header := HBoxContainer.new()
	root_vbox.add_child(header)

	title_lbl = Label.new()
	title_lbl.text = "Select Alley & Mode"
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_lbl)

	var close_btn := Button.new()
	close_btn.text = "Back"
	close_btn.pressed.connect(func():
		visible = false
		closed.emit()
	)
	header.add_child(close_btn)

	# Mode selector bar
	var mode_hbox := HBoxContainer.new()
	mode_hbox.add_theme_constant_override("separation", 6)
	root_vbox.add_child(mode_hbox)

	var mode_lbl := Label.new()
	mode_lbl.text = "Mode:"
	mode_lbl.add_theme_font_size_override("font_size", 14)
	mode_hbox.add_child(mode_lbl)

	var modes := [
		{"id": SimConstants.GameMode.SUNNY, "name": "Sunny"},
		{"id": SimConstants.GameMode.ALLEY, "name": "Alley"},
		{"id": SimConstants.GameMode.NIGHT, "name": "Night"},
		{"id": SimConstants.GameMode.LAST_WHISKER, "name": "Last Whisker"},
		{"id": SimConstants.GameMode.BARE_PAW, "name": "Bare Paw"},
		{"id": 5, "name": "Testing Lab"},
		{"id": 6, "name": "Alley Crawl"}
	]
	for m in modes:
		var mb := Button.new()
		mb.text = m["name"]
		mb.custom_minimum_size = Vector2(90, 32)
		mb.pressed.connect(func():
			selected_mode = int(m["id"])
			_refresh_mode_buttons()
		)
		mode_hbox.add_child(mb)
		mode_buttons[int(m["id"])] = mb

	root_vbox.add_child(HSeparator.new())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(scroll)

	cards_grid = GridContainer.new()
	cards_grid.columns = 4
	cards_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards_grid.add_theme_constant_override("h_separation", 10)
	cards_grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(cards_grid)

	_refresh_mode_buttons()

func _refresh_mode_buttons() -> void:
	for mid in mode_buttons.keys():
		var b: Button = mode_buttons[mid]
		var active: bool = (int(mid) == selected_mode)
		b.add_theme_stylebox_override("normal", WoodTheme.button_style(
			Color(1.0, 0.88, 0.42) if active else Color(0.75, 0.56, 0.25),
			Color(0.56, 0.34, 0.14) if active else Color(0.28, 0.16, 0.08)
		))
		b.add_theme_color_override("font_color", Color(1.0, 0.92, 0.48) if active else Color(0.88, 0.82, 0.72))

func refresh() -> void:
	if cards_grid == null:
		return
	for child in cards_grid.get_children():
		child.queue_free()

	var medals_all: Dictionary = save_mgr.data.get("medals", {}) if save_mgr != null else {}
	for m in MAPS_CATALOG:
		var map_id: String = m["id"]
		var map_medals: Dictionary = medals_all.get(map_id, {})
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(215, 112)
		card.add_theme_stylebox_override("panel", WoodTheme.card_style(false))
		cards_grid.add_child(card)

		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 6)
		card.add_child(cv)

		var top_row := HBoxContainer.new()
		cv.add_child(top_row)

		var name_lbl := Label.new()
		name_lbl.text = m["name"]
		name_lbl.add_theme_font_size_override("font_size", 14)
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		top_row.add_child(name_lbl)

		var band_lbl := Label.new()
		band_lbl.text = m["band"]
		band_lbl.add_theme_font_size_override("font_size", 12)
		band_lbl.add_theme_color_override("font_color", Color(0.95, 0.78, 0.40))
		top_row.add_child(band_lbl)

		# Medal row: Sunny, Alley, Night, Last Whisker, Bare Paw (filled pip vs empty pip)
		var medal_row := HBoxContainer.new()
		medal_row.add_theme_constant_override("separation", 6)
		cv.add_child(medal_row)

		for md in MEDAL_MODES:
			var earned := bool(map_medals.get(md["key"], false))
			var pip := Label.new()
			pip.text = "●" if earned else "○"
			pip.add_theme_font_size_override("font_size", 14)
			pip.add_theme_color_override("font_color", md["col"] if earned else Color(0.45, 0.38, 0.32))
			pip.tooltip_text = "%s: %s" % [md["name"], "Earned" if earned else "Unearned"]
			medal_row.add_child(pip)

		var play_btn := Button.new()
		play_btn.text = "Play"
		play_btn.custom_minimum_size = Vector2(0, 28)
		play_btn.pressed.connect(func():
			visible = false
			map_mode_selected.emit(map_id, selected_mode)
		)
		cv.add_child(play_btn)
