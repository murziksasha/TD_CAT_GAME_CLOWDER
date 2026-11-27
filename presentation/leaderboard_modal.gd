# Clowder: Alley Siege - Top 100 Leaderboard Modal Screen
class_name LeaderboardModal
extends PanelContainer

const SimLeaderboardManager = preload("res://sim/leaderboard_manager.gd")
const SimConstants = preload("res://sim/constants.gd")

signal closed

var lead_mgr: SimLeaderboardManager = null
var map_filter_btn: OptionButton = null
var mode_filter_btn: OptionButton = null
var table_vbox: VBoxContainer = null
var player_rank_summary_lbl: Label = null

func setup(p_lead_mgr: SimLeaderboardManager) -> void:
	lead_mgr = p_lead_mgr
	_build_ui()
	refresh()

func _build_ui() -> void:
	custom_minimum_size = Vector2(760, 560)
	offset_left = 260.0
	offset_top = 80.0
	offset_right = 1020.0
	offset_bottom = 640.0

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 10)
	add_child(root_vbox)

	# 1. Header
	var header_hbox := HBoxContainer.new()
	root_vbox.add_child(header_hbox)

	var title_lbl := Label.new()
	title_lbl.text = "Alley Keepers — Top 100"
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(title_lbl)

	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(func():
		visible = false
		closed.emit()
	)
	header_hbox.add_child(close_btn)

	# 2. Player summary
	player_rank_summary_lbl = Label.new()
	player_rank_summary_lbl.text = "Your standing: Calculating..."
	player_rank_summary_lbl.add_theme_font_size_override("font_size", 13)
	player_rank_summary_lbl.add_theme_color_override("font_color", Color(0.85, 0.95, 0.8))
	root_vbox.add_child(player_rank_summary_lbl)

	# 3. Filters
	var filter_hbox := HBoxContainer.new()
	filter_hbox.add_theme_constant_override("separation", 12)
	root_vbox.add_child(filter_hbox)

	var map_lbl := Label.new()
	map_lbl.text = "Map:"
	filter_hbox.add_child(map_lbl)

	map_filter_btn = OptionButton.new()
	map_filter_btn.custom_minimum_size = Vector2(180, 32)
	map_filter_btn.add_item("All Maps", 0)
	map_filter_btn.set_item_metadata(0, "")
	
	var maps_list = [
		{"id": "sunny_gutter", "name": "🟢 Sunny Gutter (B)"},
		{"id": "lantern_stoop", "name": "🟢 Lantern Stoop (B)"},
		{"id": "crabapple_bend", "name": "🟢 Crabapple Bend (B)"},
		{"id": "twin_gutters", "name": "🟠 Twin Gutters (I)"},
		{"id": "stall_row", "name": "🟡 Stall Row (B+)"},
		{"id": "puddle_court", "name": "🟡 Puddle Court (B+)"},
		{"id": "chimney_step", "name": "🟠 Chimney Step (I)"},
		{"id": "fishbone_straight", "name": "🟢 Fishbone Straight (B)"},
		{"id": "sack_corner", "name": "🟡 Sack Corner (B+)"},
		{"id": "welcome_bridge", "name": "🟠 Welcome Bridge (I)"},
		{"id": "morning_arch", "name": "🟢 Morning Arch (B)"},
		{"id": "spice_arcade", "name": "🟡 Spice Arcade (B+)"},
		{"id": "herring_square", "name": "🟡 Herring Square (B+)"},
		{"id": "copper_scale", "name": "🟠 Copper Scale (I)"},
		{"id": "basket_bridge", "name": "🟠 Basket Bridge (I)"},
		{"id": "fig_and_twine", "name": "🟡 Fig & Twine (B+)"},
		{"id": "weigh_house", "name": "🟠 Weigh House (I)"},
		{"id": "two_purse_lane", "name": "🔴 Two-Purse Lane (A)"},
		{"id": "canopy_cross", "name": "🟠 Canopy Cross (I)"},
		{"id": "night_onion", "name": "🔴 Night Onion (A)"},
		{"id": "grand_bazaar", "name": "🔴 Grand Bazaar (A)"},
		{"id": "market_lane", "name": "🟡 Market Lane (B+)"},
		{"id": "rooftop_crossing", "name": "🟠 Rooftop Crossing (I)"},
		{"id": "fishmarket_maze", "name": "🔴 Fishmarket Maze (A)"},
		{"id": "canal_night", "name": "🔴 Canal Night (A)"},
		{"id": "the_warren", "name": "🟣 The Warren (E)"}
	]
	for i in range(maps_list.size()):
		var idx = i + 1
		map_filter_btn.add_item(maps_list[i].name, idx)
		map_filter_btn.set_item_metadata(idx, maps_list[i].id)
	map_filter_btn.item_selected.connect(func(_idx): refresh())
	filter_hbox.add_child(map_filter_btn)

	var mode_lbl := Label.new()
	mode_lbl.text = "Mode:"
	filter_hbox.add_child(mode_lbl)

	mode_filter_btn = OptionButton.new()
	mode_filter_btn.custom_minimum_size = Vector2(160, 32)
	mode_filter_btn.add_item("All Modes", 0)
	mode_filter_btn.add_item("Sunny (40r)", 1)
	mode_filter_btn.add_item("Alley (60r)", 2)
	mode_filter_btn.add_item("Night (80r)", 3)
	mode_filter_btn.add_item("Last Whisker", 4)
	mode_filter_btn.add_item("Bare Paw", 5)
	mode_filter_btn.item_selected.connect(func(_idx): refresh())
	filter_hbox.add_child(mode_filter_btn)

	root_vbox.add_child(HSeparator.new())

	# 4. Table Header
	var th_box := HBoxContainer.new()
	th_box.add_theme_constant_override("separation", 6)
	root_vbox.add_child(th_box)

	_add_table_cell(th_box, "Rank", 50, Color(1.0, 0.85, 0.4))
	_add_table_cell(th_box, "Keeper", 140, Color(1.0, 0.85, 0.4))
	_add_table_cell(th_box, "Hero", 80, Color(1.0, 0.85, 0.4))
	_add_table_cell(th_box, "Map (Tier)", 150, Color(1.0, 0.85, 0.4))
	_add_table_cell(th_box, "Mode", 90, Color(1.0, 0.85, 0.4))
	_add_table_cell(th_box, "Wave", 60, Color(1.0, 0.85, 0.4))
	_add_table_cell(th_box, "Score", 80, Color(1.0, 0.85, 0.4))
	_add_table_cell(th_box, "Date", 70, Color(1.0, 0.85, 0.4))

	# 5. Table Rows Scroll
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 360)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(scroll)

	table_vbox = VBoxContainer.new()
	table_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	table_vbox.add_theme_constant_override("separation", 4)
	scroll.add_child(table_vbox)

func _add_table_cell(parent: HBoxContainer, text: String, width: int, color: Color = Color.WHITE) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.custom_minimum_size = Vector2(width, 24)
	lbl.add_theme_color_override("font_color", color)
	parent.add_child(lbl)
	return lbl

func refresh() -> void:
	if lead_mgr == null or table_vbox == null:
		return

	for c in table_vbox.get_children():
		c.queue_free()

	var map_meta = map_filter_btn.get_item_metadata(map_filter_btn.selected) if map_filter_btn != null else ""
	var map_filter = str(map_meta) if map_meta != null else ""
	var mode_filter = (mode_filter_btn.selected - 1) if (mode_filter_btn != null and mode_filter_btn.selected > 0) else -1

	var list = lead_mgr.get_top_100(map_filter, mode_filter)
	var mode_names = ["Sunny", "Alley", "Night", "Whisker", "BarePaw"]
	var best_local_rank = -1

	for item in list:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)

		var is_local: bool = bool(item.get("is_local_player", false))
		var r_num: int = int(item.get("rank", 0))
		if is_local and (best_local_rank == -1 or r_num < best_local_rank):
			best_local_rank = r_num

		var text_color = Color(1.0, 0.9, 0.3) if is_local else Color.WHITE
		var rank_str = "#%d" % r_num
		if r_num == 1: rank_str = "🥇 #1"
		elif r_num == 2: rank_str = "🥈 #2"
		elif r_num == 3: rank_str = "🥉 #3"

		var name_str = str(item.get("name", "Unknown"))
		if is_local:
			name_str = "★ " + name_str + " [YOU]"

		var hero_str = str(item.get("hero", "mittens")).capitalize()
		var map_str = str(item.get("map", "")).replace("_", " ").capitalize()
		var m_val: int = int(item.get("mode", 0))
		var mode_str = mode_names[clampi(m_val, 0, mode_names.size() - 1)]
		var wave_str = "%dr %s" % [int(item.get("wave", 0)), "✓" if item.get("won", false) else "✗"]
		var score_str = "%d" % int(item.get("score", 0))
		var date_str = str(item.get("date", ""))

		_add_table_cell(row, rank_str, 50, Color(1.0, 0.8, 0.2) if r_num <= 3 else text_color)
		_add_table_cell(row, name_str, 140, text_color)
		_add_table_cell(row, hero_str, 80, text_color)
		_add_table_cell(row, map_str, 150, text_color)
		_add_table_cell(row, mode_str, 90, text_color)
		_add_table_cell(row, wave_str, 60, text_color)
		_add_table_cell(row, score_str, 80, Color(0.4, 1.0, 0.4) if is_local else text_color)
		_add_table_cell(row, date_str, 70, Color(0.7, 0.7, 0.7))

		table_vbox.add_child(row)

	if best_local_rank > 0:
		player_rank_summary_lbl.text = "🏆 Your Best Ranking in this view: Rank #%d in Top 100!" % best_local_rank
		player_rank_summary_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.3))
	else:
		player_rank_summary_lbl.text = "Play and clear matches to place your clowder on the Top 100 Leaderboard!"
		player_rank_summary_lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 0.9))
