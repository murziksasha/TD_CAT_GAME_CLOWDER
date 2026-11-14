# Clowder: Alley Siege - Insights Passive Tree Modal
class_name InsightsModal
extends PanelContainer

const SimSaveManager = preload("res://sim/save_manager.gd")

signal closed

var save_mgr: SimSaveManager
var current_tree: String = "alley"
var insights_data: Dictionary = {}

var points_lbl: Label
var trees_hbox: HBoxContainer
var perks_vbox: VBoxContainer

func setup(p_save_mgr: SimSaveManager) -> void:
	save_mgr = p_save_mgr
	_load_insights_data()
	_build_ui()
	_select_tree("alley")

func _load_insights_data() -> void:
	var f = FileAccess.open("res://content/insights.json", FileAccess.READ)
	if f:
		insights_data = JSON.parse_string(f.get_as_text())
		f.close()

func _build_ui() -> void:
	custom_minimum_size = Vector2(980, 620)
	offset_left = 150.0
	offset_top = 50.0
	offset_right = 1130.0
	offset_bottom = 670.0

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 8)
	add_child(root_vbox)

	# Top Bar
	var top_hbox := HBoxContainer.new()
	root_vbox.add_child(top_hbox)

	var title_lbl := Label.new()
	title_lbl.text = "🔮 Insights — Passive Skill Trees"
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_color_override("font_color", Color(0.85, 0.7, 1.0))
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(title_lbl)

	points_lbl = Label.new()
	points_lbl.text = "Available Points: 0"
	points_lbl.add_theme_font_size_override("font_size", 16)
	points_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	top_hbox.add_child(points_lbl)

	var respec_btn := Button.new()
	respec_btn.text = " ↺ Free Respec "
	respec_btn.pressed.connect(_on_respec_pressed)
	top_hbox.add_child(respec_btn)

	var close_btn := Button.new()
	close_btn.text = " ✕ Close "
	close_btn.pressed.connect(func():
		visible = false
		closed.emit()
	)
	top_hbox.add_child(close_btn)

	root_vbox.add_child(HSeparator.new())

	# Tree Selector Tabs
	trees_hbox = HBoxContainer.new()
	trees_hbox.add_theme_constant_override("separation", 8)
	root_vbox.add_child(trees_hbox)

	var tree_names = {
		"alley": "Alley Tree",
		"hunt": "Hunt Tree",
		"myth": "Myth Tree",
		"den": "Den Tree",
		"hero": "Hero Tree",
		"clowder": "Clowder Tree"
	}

	for tid in tree_names.keys():
		var btn := Button.new()
		btn.text = tree_names[tid]
		btn.custom_minimum_size = Vector2(130, 36)
		btn.pressed.connect(func(): _select_tree(tid))
		trees_hbox.add_child(btn)

	root_vbox.add_child(HSeparator.new())

	# Perks Scroll Area
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_vbox.add_child(scroll)

	perks_vbox = VBoxContainer.new()
	perks_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	perks_vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(perks_vbox)

func _update_points_display() -> void:
	if save_mgr != null and points_lbl != null:
		var pts = int(save_mgr.data.get("account", {}).get("insight_points", 0))
		points_lbl.text = "Available Insight Points: %d  " % pts

func _select_tree(tree_id: String) -> void:
	current_tree = tree_id
	_update_points_display()

	for child in perks_vbox.get_children():
		perks_vbox.remove_child(child)
		child.queue_free()

	var trees: Dictionary = insights_data.get("trees", {})
	var perks: Array = trees.get(tree_id, [])
	var owned: Array = save_mgr.data.get("account", {}).get("insight_purchases", []) if save_mgr else []

	for i in range(perks.size()):
		var p: Dictionary = perks[i]
		var pid: String = p.get("id", "")
		var is_owned = owned.has(pid)
		var cost = int(p.get("cost", 1))

		var perk_panel := PanelContainer.new()
		var p_hbox := HBoxContainer.new()
		p_hbox.add_theme_constant_override("separation", 12)
		perk_panel.add_child(p_hbox)

		var info_vbox := VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		p_hbox.add_child(info_vbox)

		var title_txt = "Tier %d: %s (Cost: %d Pt%s)" % [
			i + 1, p.get("name", pid), cost, "s" if cost > 1 else ""
		]
		var title_lbl := Label.new()
		title_lbl.text = title_txt
		title_lbl.add_theme_font_size_override("font_size", 16)
		title_lbl.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0) if not is_owned else Color(0.5, 1.0, 0.5))
		info_vbox.add_child(title_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text = p.get("desc", "")
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info_vbox.add_child(desc_lbl)

		# Mastery requirement info if any
		var req = p.get("req_mastery", {})
		if not req.is_empty():
			var req_lbl := Label.new()
			var req_cat = req.get("cat", req.get("category", ""))
			var req_rank = req.get("rank", 1)
			req_lbl.text = "Requires: %s Mastery Rank %d" % [req_cat.capitalize(), req_rank]
			req_lbl.add_theme_color_override("font_color", Color(1.0, 0.7, 0.4))
			info_vbox.add_child(req_lbl)

		# Action Button
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(130, 40)
		if is_owned:
			btn.text = "✓ UNLOCKED"
			btn.disabled = true
		else:
			btn.text = "Unlock (%d Pt)" % cost
			var can_buy = _can_buy_perk(p, i, owned)
			btn.disabled = not can_buy
			if can_buy:
				btn.pressed.connect(func(): _buy_perk(pid, cost))

		p_hbox.add_child(btn)
		perks_vbox.add_child(perk_panel)

func _can_buy_perk(p: Dictionary, perk_idx: int, owned: Array) -> bool:
	if save_mgr == null:
		return false
	var pts = int(save_mgr.data.get("account", {}).get("insight_points", 0))
	var cost = int(p.get("cost", 1))
	if pts < cost:
		return false

	# Must have unlocked previous tier in this tree
	if perk_idx > 0:
		var trees: Dictionary = insights_data.get("trees", {})
		var prev_perk: Dictionary = trees.get(current_tree, [])[perk_idx - 1]
		if not owned.has(prev_perk.get("id", "")):
			return false

	# Check Mastery requirement
	var req: Dictionary = p.get("req_mastery", {})
	if not req.is_empty() and req.has("cat"):
		var cat_id: String = req.get("cat", "")
		var req_rank: int = int(req.get("rank", 1))
		if save_mgr.get_mastery_rank(cat_id) < req_rank:
			return false

	return true

func _buy_perk(pid: String, cost: int) -> void:
	if save_mgr == null:
		return
	var acc: Dictionary = save_mgr.data.get("account", {})
	var pts = int(acc.get("insight_points", 0))
	if pts >= cost:
		acc["insight_points"] = pts - cost
		var owned: Array = acc.get("insight_purchases", [])
		owned.append(pid)
		acc["insight_purchases"] = owned
		save_mgr.data["account"] = acc
		save_mgr.save_profile()
		_select_tree(current_tree)

func _on_respec_pressed() -> void:
	if save_mgr == null:
		return
	var acc: Dictionary = save_mgr.data.get("account", {})
	var owned: Array = acc.get("insight_purchases", [])
	if owned.is_empty():
		return

	# Calculate refund points
	var trees: Dictionary = insights_data.get("trees", {})
	var refunded_points = 0
	for t_id in trees.keys():
		for p in trees[t_id]:
			if owned.has(p.get("id", "")):
				refunded_points += int(p.get("cost", 1))

	acc["insight_points"] = int(acc.get("insight_points", 0)) + refunded_points
	acc["insight_purchases"] = []
	save_mgr.data["account"] = acc
	save_mgr.save_profile()
	_select_tree(current_tree)
