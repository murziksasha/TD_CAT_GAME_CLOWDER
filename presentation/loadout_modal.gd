class_name LoadoutModal
extends PanelContainer

const SimConstants = preload("res://sim/constants.gd")
const SimSaveManager = preload("res://sim/save_manager.gd")
const WoodTheme = preload("res://presentation/wood_theme.gd")

signal start_match(map_id: String, mode: int, hero_id: String, tricks: Array[String])
signal back_pressed

const HEROES := [
	{"id": "mittens", "name": "Mittens", "role": "Alley Scout • Speed & Crit"},
	{"id": "duchess", "name": "Duchess", "role": "Satin Diva • Range & Charm"},
	{"id": "baron", "name": "Baron Salt", "role": "Harbor Captain • Heavy Bite"},
	{"id": "pebble", "name": "Sister Pebble", "role": "Cloister • Ward & Bless"}
]

const TRICK_SLOTS := [
	{"id": "tuna_strike", "name": "Tuna Strike"},
	{"id": "night_lantern", "name": "Night Lantern"},
	{"id": "catnip_frenzy", "name": "Catnip Frenzy"}
]

var save_mgr: SimSaveManager
var cat_sprites: Dictionary = {}
var map_id: String = "sunny_gutter"
var mode: int = SimConstants.GameMode.SUNNY
var selected_hero_id: String = "mittens"
var selected_tricks: Array[String] = ["tuna_strike", "night_lantern", "catnip_frenzy"]

var header_lbl: Label
var hero_buttons: Dictionary = {}
var trick_buttons: Array[Button] = []
var tricks_note_lbl: Label
var insights_lbl: Label
var insights_btn: Button
var strikethrough_overlay_tricks: ColorRect
var strikethrough_overlay_insights: ColorRect

func setup(p_save_mgr: SimSaveManager, p_cat_sprites: Dictionary) -> void:
	save_mgr = p_save_mgr
	cat_sprites = p_cat_sprites
	_build_ui()

func open_for(p_map_id: String, p_mode: int) -> void:
	map_id = p_map_id
	mode = p_mode
	visible = true
	refresh()

func _get_icon(tex: Texture2D) -> Texture2D:
	if tex == null:
		return null
	if tex.get_width() > tex.get_height() and tex.get_height() >= 32:
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		var h := tex.get_height()
		atlas.region = Rect2(0, 0, h, h)
		return atlas
	return tex

func _build_ui() -> void:
	custom_minimum_size = Vector2(760, 500)
	offset_left = 260.0
	offset_top = 110.0
	offset_right = 1020.0
	offset_bottom = 610.0

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	add_child(vbox)

	var top := HBoxContainer.new()
	vbox.add_child(top)
	header_lbl = Label.new()
	header_lbl.text = "Loadout"
	header_lbl.add_theme_font_size_override("font_size", 20)
	header_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	header_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(header_lbl)

	var back_btn := Button.new()
	back_btn.text = "Back"
	back_btn.pressed.connect(func():
		visible = false
		back_pressed.emit()
	)
	top.add_child(back_btn)

	vbox.add_child(HSeparator.new())

	var hero_heading := Label.new()
	hero_heading.text = "Hero Commander"
	hero_heading.add_theme_font_size_override("font_size", 15)
	vbox.add_child(hero_heading)

	var hero_hbox := HBoxContainer.new()
	hero_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(hero_hbox)

	for h in HEROES:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(165, 92)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var hv := VBoxContainer.new()
		hv.set_anchors_preset(Control.PRESET_FULL_RECT)
		hv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hv.alignment = BoxContainer.ALIGNMENT_CENTER
		btn.add_child(hv)

		var pic := TextureRect.new()
		pic.custom_minimum_size = Vector2(44, 44)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.texture = _get_icon(cat_sprites.get(h["id"]))
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hv.add_child(pic)

		var nl := Label.new()
		nl.text = h["name"]
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nl.add_theme_font_size_override("font_size", 13)
		nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hv.add_child(nl)

		var rl := Label.new()
		rl.text = h["role"]
		rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rl.add_theme_font_size_override("font_size", 10)
		rl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hv.add_child(rl)

		btn.pressed.connect(func():
			selected_hero_id = h["id"]
			refresh()
		)
		hero_hbox.add_child(btn)
		hero_buttons[h["id"]] = btn

	vbox.add_child(HSeparator.new())

	# Tricks section
	var tricks_wrap := VBoxContainer.new()
	tricks_wrap.add_theme_constant_override("separation", 6)
	vbox.add_child(tricks_wrap)

	tricks_note_lbl = Label.new()
	tricks_note_lbl.text = "Tricks (3 Slots)"
	tricks_note_lbl.add_theme_font_size_override("font_size", 15)
	tricks_wrap.add_child(tricks_note_lbl)

	var tricks_row := HBoxContainer.new()
	tricks_row.add_theme_constant_override("separation", 8)
	tricks_wrap.add_child(tricks_row)

	trick_buttons.clear()
	for trk in TRICK_SLOTS:
		var tb := Button.new()
		tb.text = trk["name"]
		tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tb.custom_minimum_size = Vector2(0, 36)
		tb.toggle_mode = true
		tb.button_pressed = true
		tricks_row.add_child(tb)
		trick_buttons.append(tb)

	# Insights summary section
	var ins_row := HBoxContainer.new()
	ins_row.add_theme_constant_override("separation", 10)
	vbox.add_child(ins_row)

	insights_lbl = Label.new()
	insights_lbl.text = "Insights: 0 active"
	insights_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	insights_lbl.add_theme_font_size_override("font_size", 14)
	ins_row.add_child(insights_lbl)

	insights_btn = Button.new()
	insights_btn.text = "Insights Enabled"
	insights_btn.custom_minimum_size = Vector2(180, 34)
	ins_row.add_child(insights_btn)

	# Strikethrough lines shown on Bare Paw
	strikethrough_overlay_tricks = ColorRect.new()
	strikethrough_overlay_tricks.color = Color(0.95, 0.35, 0.28, 0.85)
	strikethrough_overlay_tricks.custom_minimum_size = Vector2(0, 2)
	strikethrough_overlay_tricks.visible = false
	tricks_note_lbl.add_child(strikethrough_overlay_tricks)
	strikethrough_overlay_tricks.set_anchors_preset(Control.PRESET_HCENTER_WIDE)
	strikethrough_overlay_tricks.offset_top = 10
	strikethrough_overlay_tricks.offset_bottom = 12

	strikethrough_overlay_insights = ColorRect.new()
	strikethrough_overlay_insights.color = Color(0.95, 0.35, 0.28, 0.85)
	strikethrough_overlay_insights.custom_minimum_size = Vector2(0, 2)
	strikethrough_overlay_insights.visible = false
	insights_lbl.add_child(strikethrough_overlay_insights)
	strikethrough_overlay_insights.set_anchors_preset(Control.PRESET_HCENTER_WIDE)
	strikethrough_overlay_insights.offset_top = 10
	strikethrough_overlay_insights.offset_bottom = 12

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var go_btn := Button.new()
	go_btn.text = "Start Match"
	go_btn.custom_minimum_size = Vector2(240, 44)
	go_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	go_btn.add_theme_color_override("font_color", Color(0.45, 0.96, 0.48))
	go_btn.pressed.connect(func():
		visible = false
		start_match.emit(map_id, mode, selected_hero_id, selected_tricks)
	)
	vbox.add_child(go_btn)

func refresh() -> void:
	var mode_names := {
		SimConstants.GameMode.SUNNY: "Sunny",
		SimConstants.GameMode.ALLEY: "Alley",
		SimConstants.GameMode.NIGHT: "Night",
		SimConstants.GameMode.LAST_WHISKER: "Last Whisker",
		SimConstants.GameMode.BARE_PAW: "Bare Paw",
		5: "Testing Lab",
		6: "Alley Crawl"
	}
	if header_lbl != null:
		header_lbl.text = "%s — %s" % [map_id.capitalize().replace("_", " "), mode_names.get(mode, "Sunny")]

	for hid in hero_buttons.keys():
		var hb: Button = hero_buttons[hid]
		var active: bool = (hid == selected_hero_id)
		hb.add_theme_stylebox_override("normal", WoodTheme.card_style(active))

	# Bare Paw law: read from mode/sim flags (Bare Paw disables Insights, Tricks, Selling, Continues)
	var bare_paw := (mode == SimConstants.GameMode.BARE_PAW)
	var bought_insights: Array = save_mgr.data.get("account", {}).get("insight_purchases", []) if save_mgr != null else []

	for tb in trick_buttons:
		tb.disabled = bare_paw
		if bare_paw:
			tb.button_pressed = false
			tb.add_theme_color_override("font_color", Color(0.65, 0.55, 0.50))
		else:
			tb.button_pressed = true
			tb.add_theme_color_override("font_color", Color(1.0, 0.95, 0.86))

	if tricks_note_lbl != null:
		tricks_note_lbl.text = "Tricks — Disabled in Bare Paw" if bare_paw else "Tricks (3 Slots)"
		tricks_note_lbl.add_theme_color_override("font_color", Color(0.85, 0.48, 0.42) if bare_paw else Color(1.0, 0.95, 0.86))
	if strikethrough_overlay_tricks != null:
		strikethrough_overlay_tricks.visible = bare_paw

	if insights_lbl != null:
		insights_lbl.text = "Insights (%d owned) — Disabled in Bare Paw" % bought_insights.size() if bare_paw else "Insights: %d passive nodes active" % bought_insights.size()
		insights_lbl.add_theme_color_override("font_color", Color(0.85, 0.48, 0.42) if bare_paw else Color(1.0, 0.95, 0.86))
	if insights_btn != null:
		insights_btn.disabled = bare_paw
		insights_btn.text = "Disabled (Bare Paw)" if bare_paw else "Active (%d)" % bought_insights.size()
	if strikethrough_overlay_insights != null:
		strikethrough_overlay_insights.visible = bare_paw
