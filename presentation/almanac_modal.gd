# Clowder: Alley Siege - Almanac Encyclopedia Modal
class_name AlmanacModal
extends PanelContainer

signal closed

var current_tab: String = "cats"
var selected_item_id: String = "pip"

# UI Containers
var tabs_hbox: HBoxContainer
var list_container: VBoxContainer
var detail_container: VBoxContainer
var cat_sprites: Dictionary = {}
var mouse_sprites: Dictionary = {}
var rat_sprites: Dictionary = {}

# Cached JSON Data (Authoritative)
var cats_data: Dictionary = {}
var heroes_data: Dictionary = {}
var mice_data: Dictionary = {}
var rats_data: Dictionary = {}
var tricks_data: Dictionary = {}

func setup(p_cat_sprites: Dictionary, p_mouse_sprites: Dictionary, p_rat_sprites: Dictionary) -> void:
	cat_sprites = p_cat_sprites
	mouse_sprites = p_mouse_sprites
	rat_sprites = p_rat_sprites
	_load_content_data()
	_build_ui()
	_select_tab("cats")

func _load_content_data() -> void:
	var cat_index := _read_json("res://content/cats/index.json")
	for raw_id in cat_index.get("ids", ["pip", "nibs", "pudding", "biscuit", "sable", "nim", "goldie", "miso"]):
		var cid := str(raw_id)
		var data := _read_json("res://content/cats/%s.json" % cid)
		if not data.is_empty():
			cats_data[cid] = data
	for hid in ["mittens", "duchess", "baron", "pebble"]:
		heroes_data[hid] = _read_json("res://content/heroes/%s.json" % hid)
	mice_data = _read_json("res://content/mice.json")
	rats_data = _read_json("res://content/rats.json")
	tricks_data = _read_json("res://content/tricks.json")

func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f = FileAccess.open(path, FileAccess.READ)
	if not f:
		return {}
	var text = f.get_as_text()
	f.close()
	var res = JSON.parse_string(text)
	return res if (res is Dictionary) else {}

func _build_ui() -> void:
	custom_minimum_size = Vector2(980, 620)
	offset_left = 150.0
	offset_top = 50.0
	offset_right = 1130.0
	offset_bottom = 670.0

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 8)
	add_child(root_vbox)

	# Header Bar
	var header_hbox := HBoxContainer.new()
	root_vbox.add_child(header_hbox)

	var title_lbl := Label.new()
	title_lbl.text = "📖 The Almanac — Cat Lore & Alley Intelligence"
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(title_lbl)

	var close_btn := Button.new()
	close_btn.text = " ✕ Close "
	close_btn.pressed.connect(func():
		visible = false
		closed.emit()
	)
	header_hbox.add_child(close_btn)

	var sep1 := HSeparator.new()
	root_vbox.add_child(sep1)

	# Navigation Tabs Bar
	tabs_hbox = HBoxContainer.new()
	tabs_hbox.add_theme_constant_override("separation", 10)
	root_vbox.add_child(tabs_hbox)

	_add_tab_button("cats", "🐱 Cats & Heroes")
	_add_tab_button("enemies", "🐭 Mice & Rats")
	_add_tab_button("tricks", "⚡ Combat Tricks")
	_add_tab_button("glossary", "📜 Tactics & Lore")

	var sep2 := HSeparator.new()
	root_vbox.add_child(sep2)

	# Main Split Body
	var body_split := HBoxContainer.new()
	body_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_split.add_theme_constant_override("separation", 16)
	root_vbox.add_child(body_split)

	# Left Column: Scrollable Item List
	var left_scroll := ScrollContainer.new()
	left_scroll.custom_minimum_size = Vector2(240, 480)
	left_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body_split.add_child(left_scroll)

	list_container = VBoxContainer.new()
	list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_container.add_theme_constant_override("separation", 4)
	left_scroll.add_child(list_container)

	# Right Column: Scrollable Detail View
	var right_scroll := ScrollContainer.new()
	right_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body_split.add_child(right_scroll)

	detail_container = VBoxContainer.new()
	detail_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_container.add_theme_constant_override("separation", 10)
	right_scroll.add_child(detail_container)

func _add_tab_button(tab_id: String, tab_title: String) -> void:
	var btn := Button.new()
	btn.text = tab_title
	btn.custom_minimum_size = Vector2(160, 36)
	btn.pressed.connect(func(): _select_tab(tab_id))
	tabs_hbox.add_child(btn)

func _select_tab(tab_id: String) -> void:
	current_tab = tab_id
	for child in list_container.get_children():
		list_container.remove_child(child)
		child.queue_free()

	match tab_id:
		"cats":
			for cid in cats_data.keys():
				var cname = cats_data[cid].get("name", cid.capitalize())
				_add_list_item(cid, cname, cat_sprites.get(cid))
			for hid in heroes_data.keys():
				var hname = heroes_data[hid].get("name", hid.capitalize()) + " ★"
				_add_list_item(hid, hname, cat_sprites.get(hid))
			_show_cat_details("pip")
		"enemies":
			var coats: Dictionary = mice_data.get("coats", {})
			for coat in coats.keys():
				_add_list_item(coat, coat.capitalize() + " Mouse", mouse_sprites.get(coat))
			var rats: Dictionary = rats_data.get("rats", {})
			for r in rats.keys():
				_add_list_item(r, r.capitalize() + " Rat [BOSS]", rat_sprites.get(r))
			_show_enemy_details("rust")
		"tricks":
			var trks: Dictionary = tricks_data.get("tricks", {})
			for tid in trks.keys():
				var tname = trks[tid].get("name", tid.capitalize())
				_add_list_item(tid, tname, null)
			_show_trick_details(trks.keys()[0] if not trks.is_empty() else "")
		"glossary":
			_show_glossary()

func _add_list_item(item_id: String, item_name: String, icon_tex: Texture2D) -> void:
	var btn := Button.new()
	btn.text = " " + item_name
	btn.custom_minimum_size = Vector2(230, 40)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	if icon_tex != null:
		btn.icon = icon_tex
		btn.expand_icon = true
		btn.add_theme_constant_override("icon_max_width", 32)
	btn.pressed.connect(func():
		selected_item_id = item_id
		if current_tab == "cats":
			_show_cat_details(item_id)
		elif current_tab == "enemies":
			_show_enemy_details(item_id)
		elif current_tab == "tricks":
			_show_trick_details(item_id)
	)
	list_container.add_child(btn)

func _clear_details() -> void:
	for child in detail_container.get_children():
		detail_container.remove_child(child)
		child.queue_free()

func _show_cat_details(cat_id: String) -> void:
	_clear_details()
	var is_hero = heroes_data.has(cat_id)
	var data_dict = heroes_data.get(cat_id, {}) if is_hero else cats_data.get(cat_id, {})

	var name_lbl := Label.new()
	name_lbl.text = data_dict.get("name", cat_id.capitalize()) + (" (Hero Commander)" if is_hero else " (Cat)")
	name_lbl.add_theme_font_size_override("font_size", 22)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	detail_container.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = data_dict.get("description", "A valiant defender of the clowder.")
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_container.add_child(desc_lbl)

	var stats_lbl := Label.new()
	var cost = data_dict.get("base_cost", data_dict.get("cost", 300))
	var range_val = data_dict.get("base_range", data_dict.get("range", 120))
	var dmg_type = data_dict.get("damage_type", "Claw")
	var cat_class = data_dict.get("category", "Alley")
	stats_lbl.text = "Base Cost: %d Kibble | Range: %d | Damage Type: %s | Category: %s" % [
		cost, range_val, dmg_type, cat_class
	]
	stats_lbl.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0))
	detail_container.add_child(stats_lbl)

	detail_container.add_child(HSeparator.new())

	if is_hero:
		var ab_title := Label.new()
		ab_title.text = "★ Hero Kit (Level 1–20 Progression):"
		ab_title.add_theme_font_size_override("font_size", 16)
		detail_container.add_child(ab_title)

		var ab1 = data_dict.get("ability_1", {})
		if not ab1.is_empty():
			var a1_lbl := Label.new()
			a1_lbl.text = "• Level 3 Active: %s (Cooldown: %ds)\n  %s" % [
				ab1.get("name", "Ability 1"), ab1.get("cooldown", 45), ab1.get("desc", "")
			]
			detail_container.add_child(a1_lbl)

		var ab2 = data_dict.get("ability_2", {})
		if not ab2.is_empty():
			var a2_lbl := Label.new()
			a2_lbl.text = "• Level 10 Active: %s (Cooldown: %ds)\n  %s" % [
				ab2.get("name", "Ability 2"), ab2.get("cooldown", 60), ab2.get("desc", "")
			]
			detail_container.add_child(a2_lbl)
	else:
		var upg_title := Label.new()
		upg_title.text = "⚔ Upgrade Paths (15 Data-Driven Upgrades):"
		upg_title.add_theme_font_size_override("font_size", 16)
		detail_container.add_child(upg_title)

		for path_key in ["path_a", "path_b", "path_c"]:
			var pdata: Dictionary = data_dict.get(path_key, {})
			var pname: String = pdata.get("name", path_key.to_upper())
			var tiers: Array = pdata.get("tiers", [])

			var p_lbl := Label.new()
			p_lbl.text = "Path %s: %s" % [path_key.substr(5, 1).to_upper(), pname]
			p_lbl.add_theme_font_size_override("font_size", 14)
			p_lbl.add_theme_color_override("font_color", Color(0.95, 0.8, 0.5))
			detail_container.add_child(p_lbl)

			for t in range(tiers.size()):
				var u = tiers[t]
				var t_lbl := Label.new()
				t_lbl.text = "  Tier %d: %s (%d Kibble) — %s" % [
					t + 1, u.get("name", ""), u.get("cost", 0), u.get("desc", "")
				]
				t_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				detail_container.add_child(t_lbl)

func _show_enemy_details(enemy_id: String) -> void:
	_clear_details()
	var coats: Dictionary = mice_data.get("coats", {})
	var rats: Dictionary = rats_data.get("rats", {})

	if coats.has(enemy_id):
		var c = coats[enemy_id]
		var title := Label.new()
		title.text = "%s Mouse (Tier Coat)" % enemy_id.capitalize()
		title.add_theme_font_size_override("font_size", 22)
		title.add_theme_color_override("font_color", Color(1.0, 0.7, 0.4))
		detail_container.add_child(title)

		var stats := Label.new()
		var spd = float(c.get("speed_multiplier", 1.0)) * 40.0
		var rbe = c.get("rbe", 1)
		var imm: Array = c.get("immunities", [])
		var imm_str = "None" if imm.is_empty() else ", ".join(imm)
		stats.text = "RBE: %d | Speed: %.1f u/s | Layer HP: %d | Immunities: %s" % [
			rbe, spd, c.get("layer_hp", 1), imm_str
		]
		detail_container.add_child(stats)

		detail_container.add_child(HSeparator.new())

		var pop_lbl := Label.new()
		var children: Array = c.get("children", [])
		if children.is_empty():
			pop_lbl.text = "Pop Reaction: Leaves no child coats (Full elimination)."
		else:
			var parts: Array[String] = []
			for ch in children:
				parts.append("%d %s" % [ch.get("count", 1), ch.get("coat", "")])
			pop_lbl.text = "Pop Cascade: Splits into %s" % ", ".join(parts)
		detail_container.add_child(pop_lbl)

	elif rats.has(enemy_id):
		var r = rats[enemy_id]
		var title := Label.new()
		title.text = "%s Rat (Siege Boss)" % enemy_id.capitalize()
		title.add_theme_font_size_override("font_size", 22)
		title.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
		detail_container.add_child(title)

		var stats := Label.new()
		var spd = float(r.get("speed_multiplier", 1.0)) * 40.0
		var rbe = r.get("rbe", 616)
		var hp = r.get("body_hp", 200)
		stats.text = "Total RBE: %d | Body HP: %d | Speed: %.1f u/s" % [rbe, hp, spd]
		detail_container.add_child(stats)

		detail_container.add_child(HSeparator.new())

		var desc := Label.new()
		if enemy_id == "matriarch":
			desc.text = "👑 Absolute Control Immunity: Rat Matriarch completely ignores stun, freeze, slow, knockback, and instant-kill effects! Only pure sustained DPS and pop overflow can defeat her."
			desc.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
		else:
			desc.text = "Visual Damage Stages: Shows visible physical wear, disheveled gear, and debris at 75%, 50%, and 25% health thresholds."
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail_container.add_child(desc)

func _show_trick_details(trick_id: String) -> void:
	_clear_details()
	var trks: Dictionary = tricks_data.get("tricks", {})
	if not trks.has(trick_id):
		return
	var t = trks[trick_id]

	var title := Label.new()
	title.text = t.get("name", trick_id.capitalize()) + " (Combat Trick)"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.5, 0.9, 1.0))
	detail_container.add_child(title)

	var stats := Label.new()
	stats.text = "Purchase Price: %d Fishcoin | In-Match Cost: %d Kibble | Cooldown: %d Rounds" % [
		t.get("price", 250), t.get("kibble_cost", 50), t.get("cooldown_rounds", 15)
	]
	detail_container.add_child(stats)

	detail_container.add_child(HSeparator.new())

	var desc := Label.new()
	var details: Array[String] = []
	if t.has("damage"):
		details.append("Deals %d %s damage in radius %.0f." % [t.get("damage", 12), t.get("damage_type", "Bite"), t.get("radius", 60.0)])
	if t.has("reveal_shadow_duration"):
		details.append("Illuminates all shadow enemies on track for %.0fs." % t.get("reveal_shadow_duration", 12.0))
	if t.has("hold_mice_duration"):
		details.append("Traps mice in place for %.0fs." % t.get("hold_mice_duration", 6.0))
	if t.has("attack_speed_bonus"):
		details.append("Boosts attack speed of all deployed cats by +%.0f%% for %.0fs." % [t.get("attack_speed_bonus", 0.5) * 100.0, t.get("duration", 8.0)])

	desc.text = "Tactical Effect:\n" + ("\n".join(details) if not details.is_empty() else "Tactical combat active.")
	desc.add_theme_font_size_override("font_size", 14)
	detail_container.add_child(desc)

func _show_glossary() -> void:
	_clear_details()
	var title := Label.new()
	title.text = "📜 Core Laws of Clowder Defense"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	detail_container.add_child(title)

	var laws: Array[Dictionary] = [
		{"name": "The Crosspath Law", "desc": "A cat can invest in at most TWO upgrade paths. Unlocking Tier 3 or higher on one path permanently caps the other path at Tier 2."},
		{"name": "Damage Immunities", "desc": "Iron coats deflect Claw. Soot coats absorb Blast. Ink coats neutralize Magic. Frost coats ignore Freeze and Chill. Bite, Acid, Void, and True damage pierce through physical coat immunities."},
		{"name": "Pop Overflow Recursion", "desc": "Excess damage beyond a coat's health cascades directly into the first inner child in the same hit WITHOUT consuming extra projectile pierce."},
		{"name": "Rat Matriarch Immunity", "desc": "The colossal empress of the warrens is completely immune to stun, freeze, slow, and knockback. Crowd control will fail against her."},
		{"name": "Selling & The Bare Paw Truth", "desc": "Selling refunds exactly 70% of total invested Kibble. In Bare Paw mode, selling, passive insights, continues, and tricks are disabled. Every map is beatable on Bare Paw!"}
	]

	for law in laws:
		var h := Label.new()
		h.text = "• " + law["name"]
		h.add_theme_font_size_override("font_size", 16)
		h.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0))
		detail_container.add_child(h)

		var p := Label.new()
		p.text = "  " + law["desc"]
		p.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail_container.add_child(p)
