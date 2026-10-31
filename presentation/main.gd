extends Node2D

const SimConstants = preload("res://sim/constants.gd")
const SimMatch = preload("res://sim/match.gd")
const SimTower = preload("res://sim/tower.gd")
const SimHero = preload("res://sim/hero.gd")
const SimFeats = preload("res://sim/feats.gd")
const SimUnit = preload("res://sim/unit.gd")
const SimProjectile = preload("res://sim/projectile.gd")

# UI node references
@onready var lives_label: Label = $CanvasLayer/HUD/TopBar/HBox/LivesLabel
@onready var kibble_label: Label = $CanvasLayer/HUD/TopBar/HBox/KibbleLabel
@onready var round_label: Label = $CanvasLayer/HUD/TopBar/HBox/RoundLabel
@onready var start_round_btn: Button = $CanvasLayer/HUD/TopBar/HBox/StartRoundButton

@onready var speed1_btn: Button = $CanvasLayer/HUD/TopBar/HBox/SpeedContainer/Speed1Btn
@onready var speed2_btn: Button = $CanvasLayer/HUD/TopBar/HBox/SpeedContainer/Speed2Btn
@onready var speed3_btn: Button = $CanvasLayer/HUD/TopBar/HBox/SpeedContainer/Speed3Btn

@onready var cat_buttons_container: HBoxContainer = $CanvasLayer/HUD/BottomDock/Scroll/CatButtons
@onready var inspector_panel: PanelContainer = $CanvasLayer/HUD/InspectorPanel
@onready var right_info_panel: PanelContainer = $CanvasLayer/HUD/RightInfoPanel

# Inspector controls
@onready var cat_title_lbl: Label = $CanvasLayer/HUD/InspectorPanel/VBox/CatTitleLabel
@onready var cat_category_lbl: Label = $CanvasLayer/HUD/InspectorPanel/VBox/CategoryLabel
@onready var stats_lbl: Label = $CanvasLayer/HUD/InspectorPanel/VBox/StatsLabel
@onready var feat_status_lbl: Label = $CanvasLayer/HUD/InspectorPanel/VBox/FeatStatusLabel
@onready var target_priority_btn: Button = $CanvasLayer/HUD/InspectorPanel/VBox/TargetPriorityBtn
@onready var path_a_btn: Button = $CanvasLayer/HUD/InspectorPanel/VBox/PathABtn
@onready var path_b_btn: Button = $CanvasLayer/HUD/InspectorPanel/VBox/PathBBtn
@onready var path_c_btn: Button = $CanvasLayer/HUD/InspectorPanel/VBox/PathCBtn
@onready var sell_btn: Button = $CanvasLayer/HUD/InspectorPanel/VBox/SellBtn
@onready var deselect_btn: Button = $CanvasLayer/HUD/InspectorPanel/VBox/DeselectBtn

@onready var hero_abilities_box: VBoxContainer = $CanvasLayer/HUD/InspectorPanel/VBox/HeroAbilitiesBox
@onready var ability1_btn: Button = $CanvasLayer/HUD/InspectorPanel/VBox/HeroAbilitiesBox/Ability1Btn
@onready var ability2_btn: Button = $CanvasLayer/HUD/InspectorPanel/VBox/HeroAbilitiesBox/Ability2Btn

# Feat Modal
@onready var feat_modal: PanelContainer = $CanvasLayer/HUD/FeatModal
@onready var feat_subtitle_lbl: Label = $CanvasLayer/HUD/FeatModal/VBox/ModalSubtitle
@onready var feat_card1_name: Label = $CanvasLayer/HUD/FeatModal/VBox/CardsHBox/Card1/VBox/Name
@onready var feat_card1_desc: Label = $CanvasLayer/HUD/FeatModal/VBox/CardsHBox/Card1/VBox/Desc
@onready var feat_card1_btn: Button = $CanvasLayer/HUD/FeatModal/VBox/CardsHBox/Card1/VBox/SelectBtn

@onready var feat_card2_name: Label = $CanvasLayer/HUD/FeatModal/VBox/CardsHBox/Card2/VBox/Name
@onready var feat_card2_desc: Label = $CanvasLayer/HUD/FeatModal/VBox/CardsHBox/Card2/VBox/Desc
@onready var feat_card2_btn: Button = $CanvasLayer/HUD/FeatModal/VBox/CardsHBox/Card2/VBox/SelectBtn

@onready var feat_card3_name: Label = $CanvasLayer/HUD/FeatModal/VBox/CardsHBox/Card3/VBox/Name
@onready var feat_card3_desc: Label = $CanvasLayer/HUD/FeatModal/VBox/CardsHBox/Card3/VBox/Desc
@onready var feat_card3_btn: Button = $CanvasLayer/HUD/FeatModal/VBox/CardsHBox/Card3/VBox/SelectBtn
@onready var feat_reroll_btn: Button = $CanvasLayer/HUD/FeatModal/VBox/RerollBtn

var sim: SimMatch
var game_speed: int = 1
var placing_cat_id: String = ""
var is_placing_hero: bool = false
var selected_tower: SimTower = null
var selected_is_hero: bool = false

var pending_feat_tower: SimTower = null
var current_feat_offer: Array[Dictionary] = []
var mouse_pos: Vector2 = Vector2.ZERO

var cat_sprites: Dictionary = {}
var mouse_sprites: Dictionary = {}
var rat_sprites: Dictionary = {}
var prop_sprites: Dictionary = {}
var grass_tex: Texture2D
var cobble_tex: Texture2D

# Colors for Mice coats
const COAT_COLORS: Dictionary = {
	"rust": Color(0.72, 0.25, 0.05),
	"slate": Color(0.44, 0.50, 0.56),
	"moss": Color(0.29, 0.49, 0.14),
	"grain": Color(0.88, 0.66, 0.00),
	"sugar": Color(0.98, 0.60, 0.68),
	"soot": Color(0.18, 0.18, 0.18),
	"frost": Color(0.39, 0.77, 0.85),
	"ink": Color(0.18, 0.09, 0.28),
	"iron": Color(0.55, 0.57, 0.60),
	"marble": Color(0.35, 0.65, 0.75),
	"prism": Color(0.85, 0.35, 0.95),
	"porcelain": Color(0.96, 0.96, 0.92)
}

const CAT_COLORS: Dictionary = {
	"pip": Color(0.90, 0.49, 0.13),
	"nibs": Color(0.20, 0.24, 0.28),
	"pudding": Color(0.85, 0.92, 0.98),
	"biscuit": Color(0.82, 0.33, 0.00),
	"sable": Color(0.15, 0.17, 0.20),
	"nim": Color(0.56, 0.27, 0.68),
	"goldie": Color(0.95, 0.61, 0.07),
	"miso": Color(0.47, 0.33, 0.28),
	"mittens": Color(0.36, 0.42, 0.49)
}

func _ready() -> void:
	_init_simulation()
	_load_art()
	_build_cat_dock()
	_connect_ui_signals()
	_apply_wood_theme()
	_update_ui()

func _load_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	return null

func _load_art() -> void:
	for id in ["pip", "nibs", "pudding", "biscuit", "sable", "nim", "goldie", "miso", "mittens"]:
		cat_sprites[id] = _load_tex("res://presentation/art/cats/%s.png" % id)
	for id in ["rust", "slate", "moss", "grain", "sugar", "soot", "frost", "ink", "iron", "marble", "prism", "porcelain"]:
		mouse_sprites[id] = _load_tex("res://presentation/art/mice/%s.png" % id)
	for id in ["burrow", "bristle", "monarch", "dusk", "matriarch"]:
		rat_sprites[id] = _load_tex("res://presentation/art/rats/%s.png" % id)
	for id in ["stall", "lantern", "crates", "puddle"]:
		prop_sprites[id] = _load_tex("res://presentation/art/props/%s.png" % id)
	grass_tex = _load_tex("res://presentation/art/tiles/grass.png")
	cobble_tex = _load_tex("res://presentation/art/tiles/cobble.png")

func _apply_wood_theme() -> void:
	var panel := _wood_panel()
	for node in [
		$CanvasLayer/HUD/TopBar,
		$CanvasLayer/HUD/BottomDock,
		$CanvasLayer/HUD/InspectorPanel,
		$CanvasLayer/HUD/RightInfoPanel,
		feat_modal,
		$CanvasLayer/HUD/FeatModal/VBox/CardsHBox/Card1,
		$CanvasLayer/HUD/FeatModal/VBox/CardsHBox/Card2,
		$CanvasLayer/HUD/FeatModal/VBox/CardsHBox/Card3
	]:
		if node is PanelContainer:
			node.add_theme_stylebox_override("panel", panel)
	var normal := _wood_button(Color(0.93, 0.72, 0.32), Color(0.40, 0.22, 0.10))
	var hover := _wood_button(Color(1.0, 0.86, 0.45), Color(0.55, 0.32, 0.12))
	var pressed := _wood_button(Color(0.75, 0.52, 0.18), Color(0.24, 0.12, 0.06))
	_theme_controls($CanvasLayer/HUD, normal, hover, pressed)

func _wood_panel() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.17, 0.10, 0.06, 0.92)
	box.border_color = Color(0.93, 0.72, 0.32)
	box.set_border_width_all(2)
	box.set_corner_radius_all(14)
	box.shadow_color = Color(0, 0, 0, 0.4)
	box.shadow_size = 10
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	return box

func _wood_button(border: Color, fill: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(8)
	box.content_margin_left = 6
	box.content_margin_right = 6
	box.content_margin_top = 4
	box.content_margin_bottom = 4
	return box

func _theme_controls(node: Node, normal: StyleBox, hover: StyleBox, pressed: StyleBox) -> void:
	if node is Button:
		node.add_theme_stylebox_override("normal", normal)
		node.add_theme_stylebox_override("hover", hover)
		node.add_theme_stylebox_override("pressed", pressed)
		node.add_theme_stylebox_override("disabled", pressed)
		node.add_theme_color_override("font_color", Color(1.0, 0.96, 0.88))
		node.add_theme_color_override("font_hover_color", Color(1.0, 0.92, 0.55))
		node.add_theme_color_override("font_disabled_color", Color(0.7, 0.62, 0.5))
	elif node is Label:
		if node.name != "LivesLabel" and node.name != "KibbleLabel":
			node.add_theme_color_override("font_color", Color(1.0, 0.95, 0.86))
	for child in node.get_children():
		_theme_controls(child, normal, hover, pressed)

func _init_simulation() -> void:
	sim = SimMatch.new()
	var mice_data = _load_json("res://content/mice.json")
	var rats_data = _load_json("res://content/rats.json")
	var sunny_rounds = _load_json("res://content/rounds/sunny.json")
	
	var cat_bps = {
		"pip": _load_json("res://content/cats/pip.json"),
		"nibs": _load_json("res://content/cats/nibs.json"),
		"pudding": _load_json("res://content/cats/pudding.json"),
		"biscuit": _load_json("res://content/cats/biscuit.json"),
		"sable": _load_json("res://content/cats/sable.json"),
		"nim": _load_json("res://content/cats/nim.json"),
		"goldie": _load_json("res://content/cats/goldie.json"),
		"miso": _load_json("res://content/cats/miso.json")
	}
	
	var hero_bps = {
		"mittens": _load_json("res://content/heroes/mittens.json"),
		"duchess": _load_json("res://content/heroes/duchess.json"),
		"baron": _load_json("res://content/heroes/baron.json"),
		"pebble": _load_json("res://content/heroes/pebble.json")
	}
	
	sim.setup(
		SimConstants.GameMode.SUNNY,
		1337,
		mice_data,
		rats_data,
		cat_bps,
		hero_bps,
		sunny_rounds
	)

func _build_cat_dock() -> void:
	for child in cat_buttons_container.get_children():
		child.queue_free()
		
	var cats_to_show = [
		{"id": "pip", "name": "Pip", "cost": 200, "is_hero": false},
		{"id": "nibs", "name": "Nibs", "cost": 280, "is_hero": false},
		{"id": "pudding", "name": "Pudding", "cost": 400, "is_hero": false},
		{"id": "biscuit", "name": "Biscuit", "cost": 525, "is_hero": false},
		{"id": "sable", "name": "Sable", "cost": 450, "is_hero": false},
		{"id": "nim", "name": "Nim", "cost": 475, "is_hero": false},
		{"id": "goldie", "name": "Goldie", "cost": 1250, "is_hero": false},
		{"id": "miso", "name": "Miso", "cost": 700, "is_hero": false},
		{"id": "mittens", "name": "Mittens ★", "cost": 600, "is_hero": true}
	]
	
	for c in cats_to_show:
		var btn = Button.new()
		var price = sim.economy.calculate_price(c["cost"])
		btn.text = "%s\n%d" % [c["name"], price]
		btn.custom_minimum_size = Vector2(108, 72)
		btn.icon = cat_sprites.get(c["id"])
		btn.expand_icon = true
		btn.add_theme_constant_override("icon_max_width", 42)
		if c["is_hero"]:
			btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		btn.pressed.connect(_on_dock_button_pressed.bind(c["id"], c["is_hero"]))
		cat_buttons_container.add_child(btn)

func _connect_ui_signals() -> void:
	start_round_btn.pressed.connect(_on_start_round_pressed)
	speed1_btn.pressed.connect(func(): _set_speed(1))
	speed2_btn.pressed.connect(func(): _set_speed(2))
	speed3_btn.pressed.connect(func(): _set_speed(3))
	
	target_priority_btn.pressed.connect(_on_cycle_target_priority)
	path_a_btn.pressed.connect(func(): _upgrade_selected("path_a"))
	path_b_btn.pressed.connect(func(): _upgrade_selected("path_b"))
	path_c_btn.pressed.connect(func(): _upgrade_selected("path_c"))
	sell_btn.pressed.connect(_on_sell_selected)
	deselect_btn.pressed.connect(_deselect_tower)
	
	ability1_btn.pressed.connect(func(): _trigger_hero_ability(1))
	ability2_btn.pressed.connect(func(): _trigger_hero_ability(2))
	
	feat_card1_btn.pressed.connect(func(): _pick_feat_card(0))
	feat_card2_btn.pressed.connect(func(): _pick_feat_card(1))
	feat_card3_btn.pressed.connect(func(): _pick_feat_card(2))
	feat_reroll_btn.pressed.connect(_on_feat_reroll_pressed)

func _set_speed(spd: int) -> void:
	game_speed = spd
	speed1_btn.disabled = (spd == 1)
	speed2_btn.disabled = (spd == 2)
	speed3_btn.disabled = (spd == 3)

func _physics_process(_delta: float) -> void:
	if sim == null:
		return
		
	# Tick according to speed multiplier
	if not feat_modal.visible:
		for _i in range(game_speed):
			sim.tick()
			
	# Check if round just finished and feats are pending
	if not sim.round_in_progress and not feat_modal.visible:
		_check_pending_feats()
		
	_update_ui()
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_pos = event.position
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_handle_left_click(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_cancel_placement_or_selection()
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			_on_start_round_pressed()
		elif event.keycode == KEY_ESCAPE:
			_cancel_placement_or_selection()
		elif event.keycode == KEY_1:
			_set_speed(1)
		elif event.keycode == KEY_2:
			_set_speed(2)
		elif event.keycode == KEY_3:
			_set_speed(3)

func _handle_left_click(click_pos: Vector2) -> void:
	# Ignore clicks on UI panels
	if click_pos.y > 600 or click_pos.x > 970 or click_pos.y < 65:
		return
		
	if placing_cat_id != "":
		# Attempt placement
		if is_placing_hero:
			var chk = sim.can_place_hero_at(placing_cat_id, click_pos)
			if chk.get("valid", false):
				var h = sim.place_hero(placing_cat_id, click_pos)
				if h != null:
					_select_hero()
					placing_cat_id = ""
		else:
			var chk = sim.can_place_tower_at(placing_cat_id, click_pos)
			if chk.get("valid", false):
				var t = sim.place_tower(placing_cat_id, click_pos)
				if t != null:
					_select_tower(t)
					placing_cat_id = ""
		return
		
	# Check if clicked existing tower
	var clicked_tower: SimTower = null
	for t in sim.towers:
		if click_pos.distance_to(t.position) <= t.footprint_radius + 6.0:
			clicked_tower = t
			break
			
	if clicked_tower != null:
		_select_tower(clicked_tower)
		return
		
	# Check if clicked hero
	if sim.hero != null and click_pos.distance_to(sim.hero.position) <= 24.0:
		_select_hero()
		return
		
	_deselect_tower()

func _cancel_placement_or_selection() -> void:
	placing_cat_id = ""
	_deselect_tower()

func _on_dock_button_pressed(cat_id: String, is_hero: bool) -> void:
	placing_cat_id = cat_id
	is_placing_hero = is_hero
	_deselect_tower()

func _select_tower(t: SimTower) -> void:
	selected_tower = t
	selected_is_hero = false
	inspector_panel.visible = true
	right_info_panel.visible = false
	hero_abilities_box.visible = false
	sell_btn.visible = true
	_update_inspector()

func _select_hero() -> void:
	selected_tower = null
	selected_is_hero = true
	inspector_panel.visible = true
	right_info_panel.visible = false
	hero_abilities_box.visible = true
	sell_btn.visible = false
	_update_inspector()

func _deselect_tower() -> void:
	selected_tower = null
	selected_is_hero = false
	inspector_panel.visible = false
	right_info_panel.visible = true

func _update_inspector() -> void:
	if selected_tower != null:
		cat_title_lbl.text = "%s — %s" % [selected_tower.cat_name, selected_tower.cat_data.get("title", "Cat")]
		cat_category_lbl.text = "%s Cat • %s Damage" % [selected_tower.category, SimConstants.damage_type_to_string(selected_tower.damage_type)]
		stats_lbl.text = "Dmg: %d | Pierce: %d | Range: %d | CD: %.2fs" % [
			selected_tower.damage, selected_tower.pierce, int(selected_tower.range_radius), selected_tower.cooldown
		]
		
		var next_xp = SimFeats.THRESHOLD_I
		if selected_tower.feat_rank == 1:
			next_xp = SimFeats.THRESHOLD_II
		elif selected_tower.feat_rank >= 2:
			next_xp = SimFeats.THRESHOLD_III
		feat_status_lbl.text = "Feat Rank: %d (XP: %d / %d)" % [selected_tower.feat_rank, int(selected_tower.feat_xp), next_xp]
		
		target_priority_btn.text = "Target: %s" % SimConstants.target_priority_to_string(selected_tower.target_priority)
		
		_update_upgrade_btn(path_a_btn, "path_a")
		_update_upgrade_btn(path_b_btn, "path_b")
		_update_upgrade_btn(path_c_btn, "path_c")
		
		var refund = int(floor(float(selected_tower.total_spent) * sim.economy.sell_refund_ratio))
		sell_btn.text = "Sell (+%d Kibble)" % refund
		sell_btn.disabled = not sim.economy.allow_selling
	elif selected_is_hero and sim.hero != null:
		var h = sim.hero
		cat_title_lbl.text = "%s (Hero Cat)" % h.hero_name
		cat_category_lbl.text = "Commander • Level %d / 20" % h.level
		stats_lbl.text = "Dmg: %d | Pierce: %d | Range: %d | CD: %.2fs" % [
			h.current_damage, h.pierce, int(h.current_range), h.current_cooldown
		]
		var next_xp = SimHero.XP_TABLE[mini(h.level, SimHero.XP_TABLE.size() - 1)]
		feat_status_lbl.text = "Hero Match XP: %d / %d" % [int(h.xp), next_xp]
		target_priority_btn.text = "Hero Auto-Target: First"
		
		path_a_btn.visible = false
		path_b_btn.visible = false
		path_c_btn.visible = false
		
		ability1_btn.text = "⚡ Pin Cushion (Lvl 3)" if h.level >= 3 else "Locked until Lvl 3"
		ability1_btn.disabled = not h.can_use_ability(1)
		if h.ability_1_cooldown_left > 0.0:
			ability1_btn.text += " (%.1fs)" % h.ability_1_cooldown_left
			
		ability2_btn.text = "⚡ Spool Barrage (Lvl 10)" if h.level >= 10 else "Locked until Lvl 10"
		ability2_btn.disabled = not h.can_use_ability(2)
		if h.ability_2_cooldown_left > 0.0:
			ability2_btn.text += " (%.1fs)" % h.ability_2_cooldown_left
	else:
		path_a_btn.visible = true
		path_b_btn.visible = true
		path_c_btn.visible = true

func _update_upgrade_btn(btn: Button, path_key: String) -> void:
	btn.visible = true
	var cur_tier = selected_tower.tiers.get(path_key, 0)
	var paths = selected_tower.cat_data.get("paths", {})
	var p_data = paths.get(path_key, {})
	var path_name = p_data.get("name", "Path")
	var t_list: Array = p_data.get("tiers", [])
	
	if cur_tier >= 5 or cur_tier >= t_list.size():
		btn.text = "%s [Tier 5/5]\nMAX TIER" % path_name
		btn.disabled = true
		return
		
	var next_tier_data: Dictionary = t_list[cur_tier]
	var tier_name = next_tier_data.get("name", "Upgrade")
	var base_cost = int(next_tier_data.get("cost", 100))
	var price = sim.economy.calculate_price(base_cost)
	
	btn.text = "%s [Tier %d/5]\n%s ($%d)" % [path_name, cur_tier, tier_name, price]
	
	if not selected_tower.can_upgrade(path_key):
		btn.disabled = true
		btn.text += " [LOCKED]"
	elif not sim.economy.can_afford(price):
		btn.disabled = true
		btn.text += " [NO KIBBLE]"
	else:
		btn.disabled = false

func _upgrade_selected(path_key: String) -> void:
	if selected_tower != null:
		if sim.upgrade_tower(selected_tower, path_key):
			_update_inspector()
			_update_ui()

func _on_sell_selected() -> void:
	if selected_tower != null:
		sim.sell_tower(selected_tower)
		_deselect_tower()
		_update_ui()

func _on_cycle_target_priority() -> void:
	if selected_tower != null:
		var p = selected_tower.target_priority
		match p:
			SimConstants.TargetPriority.FIRST:
				selected_tower.target_priority = SimConstants.TargetPriority.LAST
			SimConstants.TargetPriority.LAST:
				selected_tower.target_priority = SimConstants.TargetPriority.STRONG
			SimConstants.TargetPriority.STRONG:
				selected_tower.target_priority = SimConstants.TargetPriority.CLOSE
			SimConstants.TargetPriority.CLOSE:
				selected_tower.target_priority = SimConstants.TargetPriority.FIRST
			_:
				selected_tower.target_priority = SimConstants.TargetPriority.FIRST
		_update_inspector()

func _trigger_hero_ability(slot: int) -> void:
	if sim.trigger_hero_ability(slot):
		_update_inspector()

func _check_pending_feats() -> void:
	var t = sim.get_pending_feat_tower()
	if t != null:
		pending_feat_tower = t
		_open_feat_dialog(t)

func _open_feat_dialog(t: SimTower) -> void:
	feat_modal.visible = true
	feat_subtitle_lbl.text = "%s reached Feat Rank %d! Choose 1 Feat perk:" % [t.cat_name, t.feat_rank]
	
	current_feat_offer = SimFeats.generate_feat_offer(
		1337,
		t.instance_id,
		t.feat_rank,
		t.get_path_bits(),
		1 if t.reroll_used else 0,
		t.cat_id
	)
	
	if current_feat_offer.size() >= 3:
		feat_card1_name.text = current_feat_offer[0].get("name", "Perk 1")
		feat_card1_desc.text = current_feat_offer[0].get("desc", "")
		
		feat_card2_name.text = current_feat_offer[1].get("name", "Perk 2")
		feat_card2_desc.text = current_feat_offer[1].get("desc", "")
		
		feat_card3_name.text = current_feat_offer[2].get("name", "Perk 3")
		feat_card3_desc.text = current_feat_offer[2].get("desc", "")
		
	feat_reroll_btn.disabled = t.reroll_used or not sim.economy.can_afford(150)

func _pick_feat_card(idx: int) -> void:
	if pending_feat_tower != null and idx < current_feat_offer.size():
		pending_feat_tower.apply_feat(current_feat_offer[idx])
		pending_feat_tower = null
		feat_modal.visible = false
		_check_pending_feats()

func _on_feat_reroll_pressed() -> void:
	if pending_feat_tower != null:
		if sim.reroll_tower_feats(pending_feat_tower):
			_open_feat_dialog(pending_feat_tower)
			_update_ui()

func _on_start_round_pressed() -> void:
	if sim != null and not feat_modal.visible:
		sim.start_next_round()
		_update_ui()

func _update_ui() -> void:
	if sim == null:
		return
	lives_label.text = "❤️ Lives: %d" % sim.lives
	kibble_label.text = "🐟 Kibble: %d" % sim.economy.kibble
	round_label.text = "Round: %d / %d (Sunny)" % [sim.current_round, sim.max_rounds]
	start_round_btn.disabled = sim.round_in_progress or sim.match_won or sim.match_lost or feat_modal.visible
	if selected_tower != null or selected_is_hero:
		_update_inspector()

# ==================== DRAWING & VISUALIZATION ====================

func _draw() -> void:
	if sim == null:
		return
	_draw_world()
	_draw_towers()
	_draw_units()
	_draw_projectiles()
	_draw_placement_preview()

func _path_points() -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(40.0, 100.0),
		Vector2(640.0, 100.0),
		Vector2(640.0, 400.0),
		Vector2(340.0, 400.0)
	])

func _draw_world() -> void:
	if grass_tex:
		draw_texture_rect(grass_tex, Rect2(0, 0, 1280, 720), false, Color(0.92, 0.98, 0.88))
	else:
		draw_rect(Rect2(0, 0, 1280, 720), Color(0.36, 0.52, 0.28))
	_draw_houses()
	_draw_cobble_path()
	_draw_prop("puddle", Vector2(860, 230), 150)
	_draw_prop("lantern", Vector2(180, 250), 90)
	_draw_prop("lantern", Vector2(760, 150), 80)
	_draw_prop("crates", Vector2(980, 520), 130)
	_draw_prop("stall", Vector2(200, 530), 170)
	draw_string(ThemeDB.fallback_font, Vector2(8, 78), "WARREN", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.95, 0.9, 0.7))
	draw_string(ThemeDB.fallback_font, Vector2(250, 455), "FISH MARKET", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.45, 0.18, 0.08))

func _draw_houses() -> void:
	var houses: Array[Rect2] = [
		Rect2(90, 175, 150, 78),
		Rect2(430, 190, 140, 70),
		Rect2(720, 70, 170, 95),
		Rect2(900, 330, 150, 80),
		Rect2(70, 500, 90, 55)
	]
	var roofs: Array[Color] = [
		Color(0.72, 0.28, 0.18),
		Color(0.55, 0.32, 0.22),
		Color(0.80, 0.45, 0.18),
		Color(0.45, 0.28, 0.38),
		Color(0.62, 0.30, 0.16)
	]
	for i in houses.size():
		var r: Rect2 = houses[i]
		draw_rect(Rect2(r.position.x + 6, r.position.y + 4, r.size.x, r.size.y), Color(0, 0, 0, 0.15))
		draw_rect(r, Color(0.95, 0.88, 0.74))
		draw_rect(Rect2(r.position.x - 8, r.position.y - 14, r.size.x + 16, 20), roofs[i])
		draw_rect(Rect2(r.position.x + 14, r.position.y + 22, 18, 16), Color(0.98, 0.82, 0.4))
		draw_rect(Rect2(r.position.x + 44, r.position.y + 22, 18, 16), Color(0.55, 0.78, 0.86))
		draw_rect(Rect2(r.position.x + r.size.x * 0.5 - 8, r.position.y + r.size.y - 22, 16, 22), Color(0.45, 0.26, 0.14))

func _draw_cobble_path() -> void:
	var pts := _path_points()
	draw_polyline(pts, Color(0.28, 0.18, 0.1), 54.0, true)
	if cobble_tex == null:
		draw_polyline(pts, Color(0.62, 0.5, 0.36), 40.0, true)
		return
	for i in range(pts.size() - 1):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var dir := (b - a).normalized()
		var length := a.distance_to(b)
		draw_set_transform(a, dir.angle(), Vector2.ONE)
		draw_texture_rect(cobble_tex, Rect2(0, -20, length, 40), false, Color(1, 0.96, 0.9))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_circle(pts[0], 16.0, Color(0.25, 0.55, 0.28, 0.9))
	draw_circle(pts[pts.size() - 1], 18.0, Color(0.75, 0.22, 0.16, 0.9))

func _draw_prop(id: String, pos: Vector2, height: float) -> void:
	var tex: Texture2D = prop_sprites.get(id)
	if tex == null:
		return
	_draw_shadow(pos + Vector2(0, height * 0.28), height * 0.28)
	_blit(tex, pos, height, 1.0, 0.55)

func _draw_towers() -> void:
	for t in sim.towers:
		var is_sel = (t == selected_tower)
		var base_col = CAT_COLORS.get(t.cat_id, Color(0.8, 0.5, 0.2))
		
		# Range indicator if selected
		if is_sel:
			draw_circle(t.position, t.range_radius, Color(base_col.r, base_col.g, base_col.b, 0.15))
			draw_arc(t.position, t.range_radius, 0, TAU, 48, Color(1.0, 0.85, 0.2, 0.8), 2.0)
			draw_arc(t.position, t.footprint_radius + 4.0, 0, TAU, 32, Color(1.0, 0.9, 0.3, 0.9), 2.5)
			
		_draw_cat_sprite(t.position, t.cat_id, t.footprint_radius, base_col, t.feat_rank)
		
	# Draw Hero if placed
	if sim.hero != null:
		var is_sel = selected_is_hero
		var h_pos = sim.hero.position
		if is_sel:
			draw_circle(h_pos, sim.hero.current_range, Color(0.4, 0.6, 1.0, 0.15))
			draw_arc(h_pos, sim.hero.current_range, 0, TAU, 48, Color(0.4, 0.8, 1.0, 0.8), 2.0)
			draw_arc(h_pos, 24.0, 0, TAU, 32, Color(1.0, 0.85, 0.2, 0.9), 2.5)
		_draw_hero_sprite(h_pos, sim.hero)

func _blit(tex: Texture2D, pos: Vector2, height: float, alpha: float, foot_anchor: float) -> void:
	var scale := height / float(tex.get_height())
	var w := float(tex.get_width()) * scale
	var top_left := pos - Vector2(w * 0.5, height * foot_anchor)
	draw_texture_rect(tex, Rect2(top_left, Vector2(w, height)), false, Color(1, 1, 1, alpha))

func _draw_shadow(pos: Vector2, radius: float) -> void:
	draw_set_transform(pos, 0.0, Vector2(1.0, 0.38))
	draw_circle(Vector2.ZERO, radius, Color(0.05, 0.07, 0.04, 0.28))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _bob(pos: Vector2) -> float:
	return sin((Time.get_ticks_msec() / 280.0) + pos.x * 0.05) * 2.2

func _draw_cat_sprite(pos: Vector2, cat_id: String, radius: float, fur_col: Color, feat_rank: int) -> void:
	var tex: Texture2D = cat_sprites.get(cat_id)
	var draw_pos := pos + Vector2(0, _bob(pos))
	_draw_shadow(pos + Vector2(0, radius * 0.35), radius * 0.85)
	if tex:
		_blit(tex, draw_pos, radius * 3.3, 1.0, 0.82)
	else:
		draw_circle(draw_pos, radius, fur_col)
		draw_circle(draw_pos + Vector2(-6, -4), 2.0, Color(0.1, 0.1, 0.1))
		draw_circle(draw_pos + Vector2(6, -4), 2.0, Color(0.1, 0.1, 0.1))
	if feat_rank > 0:
		var stars = "★" if feat_rank == 1 else ("★★" if feat_rank == 2 else "★★★")
		draw_string(ThemeDB.fallback_font, draw_pos + Vector2(-14.0, -radius * 1.7), stars, HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color(1.0, 0.85, 0.2))

func _draw_hero_sprite(pos: Vector2, h: SimHero) -> void:
	var hero_tex_id: String = h.id if cat_sprites.get(h.id) != null else "mittens"
	_draw_cat_sprite(pos, hero_tex_id, 22.0, Color(0.40, 0.45, 0.52), 0)
	draw_string(ThemeDB.fallback_font, pos + Vector2(-16.0, -40.0), "LV %d" % h.level, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1.0, 0.9, 0.35))

func _draw_units() -> void:
	for u in sim.units:
		if not u.is_alive:
			continue
		var pos = sim.get_point_on_path(u.s)
		
		if u.is_rat:
			_draw_rat(pos, u)
		else:
			_draw_mouse(pos, u)

func _draw_mouse(pos: Vector2, u: SimUnit) -> void:
	var alpha = 0.45 if u.is_shadow else 1.0
	var height = 34.0 if u.unit_type == "porcelain" else 28.0
	var tex: Texture2D = mouse_sprites.get(u.unit_type)
	_draw_shadow(pos + Vector2(0, 6), 10.0)
	if u.is_plated:
		draw_arc(pos, 16.0, 0, TAU, 20, Color(0.92, 0.92, 0.96, alpha), 2.0)
	if tex:
		_blit(tex, pos, height, alpha, 0.72)
	else:
		var col: Color = COAT_COLORS.get(u.unit_type, Color(0.8, 0.2, 0.2))
		col.a = alpha
		draw_circle(pos, 11.0, col)
	if u.unit_type == "porcelain":
		draw_string(ThemeDB.fallback_font, pos + Vector2(-6, 4), str(u.layer_hp), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.15, 0.2, 0.35))
	if u.is_shadow:
		draw_string(ThemeDB.fallback_font, pos + Vector2(-5, -18), "✦", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.85, 0.55, 1.0))
	if u.is_gnaw:
		draw_circle(pos + Vector2(10, -12), 3.0, Color(0.25, 0.8, 0.25, alpha))

func _draw_rat(pos: Vector2, u: SimUnit) -> void:
	var r = 28.0
	var height = 70.0
	match u.unit_type:
		"bristle":
			r = 32.0
			height = 82.0
		"monarch":
			r = 36.0
			height = 96.0
		"dusk":
			r = 30.0
			height = 78.0
		"matriarch":
			r = 42.0
			height = 112.0
	if u.is_plated:
		draw_arc(pos, r + 4.0, 0, TAU, 28, Color(0.9, 0.9, 0.95), 3.0)
	_draw_shadow(pos + Vector2(0, 8), r * 0.7)
	var tex: Texture2D = rat_sprites.get(u.unit_type)
	if tex:
		_blit(tex, pos, height, 1.0, 0.78)
	else:
		draw_circle(pos, r, Color(0.45, 0.28, 0.2))
	var bar_w = 64.0
	var bar_h = 7.0
	var bar_pos = pos + Vector2(-bar_w * 0.5, -height * 0.72)
	draw_rect(Rect2(bar_pos, Vector2(bar_w, bar_h)), Color(0.2, 0.2, 0.2, 0.9))
	
	var hp_ratio = clampf(float(u.body_hp) / maxf(1.0, float(u.max_body_hp)), 0.0, 1.0)
	var hp_col = Color(0.2, 0.85, 0.3).lerp(Color(0.9, 0.2, 0.2), 1.0 - hp_ratio)
	draw_rect(Rect2(bar_pos, Vector2(bar_w * hp_ratio, bar_h)), hp_col)
	draw_rect(Rect2(bar_pos, Vector2(bar_w, bar_h)), Color(0.9, 0.9, 0.9, 0.7), false, 1.0)
	
	var hp_text = "%d/%d" % [u.body_hp, u.max_body_hp]
	draw_string(ThemeDB.fallback_font, bar_pos + Vector2(0, -12), hp_text, HORIZONTAL_ALIGNMENT_CENTER, int(bar_w), 11, Color.WHITE)

func _draw_projectiles() -> void:
	for p in sim.projectiles:
		if not p.is_active:
			continue
		if p.is_explosion:
			draw_circle(p.position, 7.0, Color(0.95, 0.45, 0.12, 0.9))
			draw_arc(p.position, 11.0, 0, TAU, 16, Color(1.0, 0.75, 0.3, 0.7), 2.0)
		else:
			var dir = (p.target_position - p.position).normalized()
			draw_line(p.position, p.position - dir * 10.0, Color(0.95, 0.35, 0.25, 0.85), 3.0)
			draw_circle(p.position, 3.2, Color(1.0, 0.92, 0.55))

func _draw_placement_preview() -> void:
	if placing_cat_id == "":
		return
		
	var valid = false
	var footprint = 20.0
	var range_r = 130.0
	var cost = 200
	
	if is_placing_hero:
		var chk = sim.can_place_hero_at(placing_cat_id, mouse_pos)
		valid = chk.get("valid", false)
		range_r = 160.0
		cost = chk.get("price", 600)
	else:
		var chk = sim.can_place_tower_at(placing_cat_id, mouse_pos)
		valid = chk.get("valid", false)
		footprint = chk.get("footprint", 20.0)
		var cdata = sim.cat_blueprints.get(placing_cat_id, {})
		range_r = float(cdata.get("base", {}).get("range", 130.0))
		cost = chk.get("price", 200)
		
	var col = Color(0.2, 0.9, 0.3, 0.35) if valid else Color(0.9, 0.2, 0.2, 0.35)
	var stroke = Color(0.2, 0.9, 0.3, 0.9) if valid else Color(0.9, 0.2, 0.2, 0.9)
	
	# Range circle
	draw_circle(mouse_pos, range_r, col)
	draw_arc(mouse_pos, range_r, 0, TAU, 48, stroke, 1.5)
	
	var ghost: Texture2D = cat_sprites.get(placing_cat_id)
	if ghost:
		_blit(ghost, mouse_pos, footprint * 3.1, 0.85 if valid else 0.45, 0.82)
	else:
		draw_circle(mouse_pos, footprint, Color(stroke.r, stroke.g, stroke.b, 0.7))
	
	var tip = "%s ($%d)" % [placing_cat_id.capitalize(), cost]
	if not valid:
		tip += " - INVALID SPOT"
	draw_string(ThemeDB.fallback_font, mouse_pos + Vector2(25, -15), tip, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, stroke)

func _load_json(path: String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text = file.get_as_text()
	var json = JSON.new()
	if json.parse(text) == OK:
		return json.data
	return {}
