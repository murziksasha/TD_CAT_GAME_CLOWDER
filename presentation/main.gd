extends Node2D

const SimConstants = preload("res://sim/constants.gd")
const SimMatch = preload("res://sim/match.gd")
const SimTestingLab = preload("res://sim/testing_lab.gd")
const TESTING_LAB_MODE = 5
const SimAlleyCrawl = preload("res://sim/alley_crawl.gd")
const SimAlleyCrawlSession = preload("res://sim/alley_crawl_session.gd")
const ALLEY_CRAWL_MODE = 6
const SimTower = preload("res://sim/tower.gd")
const SimHero = preload("res://sim/hero.gd")
const SimFeats = preload("res://sim/feats.gd")
const SimUnit = preload("res://sim/unit.gd")
const SimProjectile = preload("res://sim/projectile.gd")
const WorldDraw = preload("res://presentation/world_draw.gd")
const ActorDraw = preload("res://presentation/actor_draw.gd")
const CombatVfx = preload("res://presentation/vfx.gd")
const PresentationAudio = preload("res://presentation/audio.gd")
const ClowderLocalization = preload("res://presentation/localization.gd")
const SimSaveManager = preload("res://sim/save_manager.gd")
const AlmanacModal = preload("res://presentation/almanac_modal.gd")
const TitleMenu = preload("res://presentation/title_menu.gd")
const InsightsModal = preload("res://presentation/insights_modal.gd")
const ShopModal = preload("res://presentation/shop_modal.gd")
const SettingsModal = preload("res://presentation/settings_modal.gd")
const LeaderboardModal = preload("res://presentation/leaderboard_modal.gd")
const CoopModal = preload("res://presentation/coop_modal.gd")
const SimLeaderboardManager = preload("res://sim/leaderboard_manager.gd")
const NetworkManager = preload("res://network/network_manager.gd")

# UI node references
@onready var lives_label: Label = $CanvasLayer/HUD/TopBar/HBox/LivesLabel
@onready var kibble_label: Label = $CanvasLayer/HUD/TopBar/HBox/KibbleLabel
@onready var round_label: Label = $CanvasLayer/HUD/TopBar/HBox/RoundLabel
@onready var start_round_btn: Button = $CanvasLayer/HUD/TopBar/HBox/StartRoundButton
var map_select_btn: OptionButton = null
var mode_select_btn: OptionButton = null
var language_btn: Button = null
var profile_badge_lbl: Label = null
var save_mgr: SimSaveManager = null

var title_menu: TitleMenu = null
var almanac_modal: AlmanacModal = null
var insights_modal: InsightsModal = null
var shop_modal: ShopModal = null
var settings_modal: SettingsModal = null
var menu_hub_btn: Button = null
var almanac_top_btn: Button = null
var shop_top_btn: Button = null
var trick_btn_hbox: HBoxContainer = null
var trick_buttons: Array[Button] = []
var current_mode: int = SimConstants.GameMode.SUNNY
var testing_lab: SimTestingLab = null
var lab_panel: PanelContainer = null
var lab_status: Label = null
var lab_round: SpinBox = null
var lab_enemy: OptionButton = null
var lab_path: OptionButton = null
var lab_dps_label: Label = null
var lab_overlay_land: bool = false
var lab_overlay_water: bool = false
var lab_overlay_perch: bool = false
var lab_overlay_blocker: bool = false
var lab_overlay_path: bool = false
var alley_crawl: SimAlleyCrawl = null
var alley_crawl_session: SimAlleyCrawlSession = null
var alley_crawl_config: Dictionary = {}
var crawl_panel: PanelContainer = null
var crawl_title: Label = null
var crawl_details: Label = null
var crawl_relic_box: HBoxContainer = null
var crawl_next_box: HBoxContainer = null
var crawl_take_curse: CheckButton = null

var lead_mgr: SimLeaderboardManager = null
var leaderboard_modal: LeaderboardModal = null
var leaderboard_top_btn: Button = null
var net_mgr: NetworkManager = null
var coop_modal: CoopModal = null
var coop_top_btn: Button = null
var coop_mode_active: bool = false
var coop_current_player: int = 1
var coop_player_toggle_btn: Button = null

var auto_wave_btn: Button = null
var auto_wave_enabled: bool = false
var auto_start_timer: float = -1.0
var auto_wave_delay: float = 0.4

@onready var speed1_btn: Button = $CanvasLayer/HUD/TopBar/HBox/SpeedContainer/Speed1Btn
@onready var speed2_btn: Button = $CanvasLayer/HUD/TopBar/HBox/SpeedContainer/Speed2Btn
@onready var speed3_btn: Button = $CanvasLayer/HUD/TopBar/HBox/SpeedContainer/Speed3Btn

@onready var cat_buttons_container: HBoxContainer = $CanvasLayer/HUD/BottomDock/Scroll/CatButtons
@onready var inspector_panel: PanelContainer = $CanvasLayer/HUD/InspectorPanel
@onready var right_info_panel: PanelContainer = $CanvasLayer/HUD/RightInfoPanel
@onready var incoming_info: Label = $CanvasLayer/HUD/RightInfoPanel/VBox/IncomingInfo

# Inspector controls
@onready var cat_title_lbl: Label = $CanvasLayer/HUD/InspectorPanel/VBox/CatTitleLabel
@onready var cat_category_lbl: Label = $CanvasLayer/HUD/InspectorPanel/VBox/CategoryLabel
@onready var stats_lbl: Label = $CanvasLayer/HUD/InspectorPanel/VBox/StatsLabel
@onready var feat_status_lbl: Label = $CanvasLayer/HUD/InspectorPanel/VBox/FeatStatusLabel
@onready var target_priority_btn: Button = $CanvasLayer/HUD/InspectorPanel/VBox/TargetPriorityBtn
@onready var brew_target_btn: Button = $CanvasLayer/HUD/InspectorPanel/VBox/BrewTargetBtn
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

# Persistent Hero Commander Panel
var hero_commander_panel: PanelContainer
var hero_cmd_portrait: TextureRect
var hero_cmd_name_lbl: Label
var hero_cmd_xp_bar: ProgressBar
var hero_cmd_ability1_btn: Button
var hero_cmd_ability2_btn: Button

# Results / Defeat & Victory Modal
var results_modal: PanelContainer
var results_title_lbl: Label
var results_stats_lbl: Label
var results_leak_lbl: Label
var results_immunity_lbl: Label
var results_coaching_lbl: Label
var results_unlock_lbl: Label
var results_retry_btn: Button
var results_map_btn: Button

# Between-round removable-clutter card. Opening it never spends Kibble; only its
# dedicated confirmation button calls the authoritative sim action.
var obstacle_card: PanelContainer
var obstacle_card_label: Label
var obstacle_clear_btn: Button
var selected_obstacle_id: String = ""

var sim: SimMatch
var game_speed: int = 1
var placing_cat_id: String = ""
var is_placing_hero: bool = false
var selected_tower: SimTower = null
var selected_is_hero: bool = false
var brew_selecting_source: SimTower = null

var pending_feat_tower: SimTower = null
var current_feat_offer: Array[Dictionary] = []
var mouse_pos: Vector2 = Vector2.ZERO

var cat_sprites: Dictionary = {}
var cat_catalog: Dictionary = {}
var cat_order: Array[String] = []
var mouse_sprites: Dictionary = {}
var rat_sprites: Dictionary = {}
var prop_sprites: Dictionary = {}
var grass_tex: Texture2D
var cobble_tex: Texture2D
var world_drawer: WorldDraw
var actor_drawer: ActorDraw
var combat_vfx: CombatVfx
var presentation_audio: PresentationAudio
var previous_unit_s: Dictionary = {}
var interpolation_alpha: float = 1.0
var current_map_id: String = "sunny_gutter"
var localization: ClowderLocalization
var match_paused := false
var world_camera: Camera2D
var camera_panel: PanelContainer
var camera_controls: HBoxContainer
const CAMERA_CENTER := Vector2(640.0, 360.0)
const CAMERA_SIZE := Vector2(1280.0, 720.0)
const CAMERA_MAX_ZOOM := 2.25
var right_drag_origin := Vector2.ZERO
var right_dragged := false
var balcony_hint_time := 0.0

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
	"bub": Color(0.42, 0.65, 0.26),
	"mittens": Color(0.36, 0.42, 0.49)
}

func _ready() -> void:
	localization = ClowderLocalization.new()
	localization.setup(_load_language_setting())
	save_mgr = SimSaveManager.new()
	save_mgr.load_profile()
	lead_mgr = SimLeaderboardManager.new()
	net_mgr = NetworkManager.new()
	add_child(net_mgr)
	auto_wave_enabled = bool(save_mgr.data.get("settings", {}).get("auto_start", false))
	_init_simulation()
	world_drawer = WorldDraw.new()
	actor_drawer = ActorDraw.new()
	combat_vfx = CombatVfx.new()
	presentation_audio = PresentationAudio.new()
	presentation_audio.setup(self)
	_setup_balcony_camera()
	_load_art()
	_build_cat_dock()
	_setup_map_select()
	_setup_mode_select()
	_setup_testing_lab_controls()
	_setup_alley_crawl_panel()
	_setup_language_toggle()
	_setup_profile_badge()
	_setup_top_bar_extra_buttons()
	_organize_top_bar()
	_setup_camera_controls()
	_connect_ui_signals()
	_setup_extended_ui()
	_setup_meta_screens()
	_apply_wood_theme()
	_update_ui()

func _load_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	return null

func _get_single_frame_icon(texture: Texture2D) -> Texture2D:
	if texture == null:
		return null
	if texture is AtlasTexture:
		return texture
	if texture.get_width() > texture.get_height() and texture.get_height() >= 32:
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		var h := texture.get_height()
		atlas.region = Rect2(0, 0, h, h)
		return atlas
	return texture

func _load_cat_catalog() -> Dictionary:
	var result: Dictionary = {}
	cat_order.clear()
	var index := _load_json("res://content/cats/index.json")
	var ids: Array = index.get("ids", ["pip", "nibs", "pudding", "biscuit", "sable", "nim", "goldie", "miso", "marlow", "bub"])
	for raw_id in ids:
		var cat_id := str(raw_id)
		var cat_data := _load_json("res://content/cats/%s.json" % cat_id)
		if not cat_data.is_empty():
			cat_order.append(cat_id)
			result[cat_id] = cat_data
	cat_catalog = result
	return result

func _load_art() -> void:
	if cat_catalog.is_empty():
		_load_cat_catalog()
	for id in cat_order + ["mittens", "duchess", "baron", "pebble"]:
		cat_sprites[id] = _load_sheet_or_static("res://presentation/art/cats/%s" % id)
	for id in ["rust", "slate", "moss", "grain", "sugar", "soot", "frost", "ink", "iron", "marble", "prism", "porcelain"]:
		mouse_sprites[id] = _load_sheet_or_static("res://presentation/art/mice/%s" % id, "_walk")
	for id in ["burrow", "bristle", "monarch", "dusk", "matriarch"]:
		rat_sprites[id] = _load_sheet_or_static("res://presentation/art/rats/%s" % id, "_walk")
	for id in ["stall", "lantern", "crates", "puddle"]:
		prop_sprites[id] = _load_tex("res://presentation/art/props/%s.png" % id)
	grass_tex = _load_tex("res://presentation/art/tiles/grass.png")
	cobble_tex = _load_tex("res://presentation/art/tiles/cobble.png")

func _load_sheet_or_static(stem: String, sheet_suffix: String = "_sheet") -> Texture2D:
	var sheet := _load_tex("%s%s.png" % [stem, sheet_suffix])
	return sheet if sheet != null else _load_tex("%s.png" % stem)

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
		$CanvasLayer/HUD/FeatModal/VBox/CardsHBox/Card3,
		hero_commander_panel,
		results_modal,
		almanac_modal,
		insights_modal,
		shop_modal,
		settings_modal,
		camera_panel
	]:
		if node is PanelContainer:
			node.add_theme_stylebox_override("panel", panel)

	# Theme dock scrollbar with matching wood & brass styling
	var scroll_bg := StyleBoxFlat.new()
	scroll_bg.bg_color = Color(0.10, 0.06, 0.04, 0.75)
	scroll_bg.set_corner_radius_all(3)
	
	var grabber := StyleBoxFlat.new()
	grabber.bg_color = Color(0.85, 0.65, 0.28, 0.85)
	grabber.border_color = Color(0.93, 0.72, 0.32)
	grabber.set_border_width_all(1)
	grabber.set_corner_radius_all(3)
	
	var grabber_hl := StyleBoxFlat.new()
	grabber_hl.bg_color = Color(1.0, 0.82, 0.45, 0.95)
	grabber_hl.border_color = Color(1.0, 0.9, 0.6)
	grabber_hl.set_border_width_all(1)
	grabber_hl.set_corner_radius_all(3)
	
	if has_node("CanvasLayer/HUD/BottomDock/Scroll"):
		var scroll_node: ScrollContainer = $CanvasLayer/HUD/BottomDock/Scroll
		var hsb: HScrollBar = scroll_node.get_h_scroll_bar()
		if hsb != null:
			hsb.custom_minimum_size = Vector2(0, 8)
			hsb.add_theme_stylebox_override("scroll", scroll_bg)
			hsb.add_theme_stylebox_override("scroll_focus", scroll_bg)
			hsb.add_theme_stylebox_override("grabber", grabber)
			hsb.add_theme_stylebox_override("grabber_highlight", grabber_hl)
			hsb.add_theme_stylebox_override("grabber_pressed", grabber_hl)

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

func _init_simulation(p_map_id: String = "", p_mode: int = -1) -> void:
	if p_map_id != "":
		current_map_id = p_map_id
	if p_mode >= 0:
		current_mode = p_mode
	if results_modal != null:
		results_modal.visible = false
	if results_retry_btn != null:
		results_retry_btn.text = "Retry Map"
	if current_mode == ALLEY_CRAWL_MODE:
		_ensure_alley_crawl_run()
		if alley_crawl != null and not alley_crawl.get_current_node().is_empty():
			current_map_id = str(alley_crawl.get_current_node().get("map_id", "sunny_gutter"))
	else:
		alley_crawl_session = null
		if crawl_panel != null:
			crawl_panel.visible = false
	sim = SimMatch.new()
	var mice_data = _load_json("res://content/mice.json")
	var rats_data = _load_json("res://content/rats.json")
	var campaign_rounds = _load_json("res://content/rounds/campaign.json")
	var round_data = campaign_rounds if not campaign_rounds.is_empty() else _load_json("res://content/rounds/sunny.json")
	var map_data = _load_json("res://content/maps/%s.json" % current_map_id)
	
	var cat_bps := _load_cat_catalog()
	
	var hero_bps = {
		"mittens": _load_json("res://content/heroes/mittens.json"),
		"duchess": _load_json("res://content/heroes/duchess.json"),
		"baron": _load_json("res://content/heroes/baron.json"),
		"pebble": _load_json("res://content/heroes/pebble.json")
	}
	
	sim.setup(
		SimConstants.GameMode.SUNNY if current_mode in [TESTING_LAB_MODE, ALLEY_CRAWL_MODE] else current_mode,
		1337,
		mice_data,
		rats_data,
		cat_bps,
		hero_bps,
		round_data,
		0,
		map_data
	)
	testing_lab = null
	if current_mode == TESTING_LAB_MODE:
		testing_lab = SimTestingLab.new()
		testing_lab.setup(sim)
		sim.replay.mode = TESTING_LAB_MODE
	alley_crawl_session = null
	if current_mode == ALLEY_CRAWL_MODE and alley_crawl != null:
		alley_crawl_session = SimAlleyCrawlSession.new()
		if alley_crawl_session.setup(alley_crawl):
			alley_crawl_session.prepare_match(sim)
			var district_rounds: Array = alley_crawl_config.get("district_rounds", [10])
			sim.max_rounds = int(district_rounds[mini(alley_crawl.current_stage, district_rounds.size() - 1)])
			sim.replay.mode = ALLEY_CRAWL_MODE
	_refresh_testing_lab_controls()
	_refresh_alley_crawl_panel(false)
	var tricks_data = _load_json("res://content/tricks.json")
	sim.load_tricks_data(tricks_data)
	selected_obstacle_id = ""
	if obstacle_card != null:
		obstacle_card.visible = false

func _build_cat_dock() -> void:
	for child in cat_buttons_container.get_children():
		child.queue_free()
		
	var cats_to_show: Array[Dictionary] = []
	for cat_id in cat_order:
		var data: Dictionary = cat_catalog.get(cat_id, {})
		cats_to_show.append({"id": cat_id, "name": data.get("name", cat_id.capitalize()), "cost": int(data.get("cost", 0)), "is_hero": false})
	cats_to_show.append_array([
		{"id": "mittens", "name": "Mittens ★", "cost": 600, "is_hero": true},
		{"id": "duchess", "name": "Duchess ★", "cost": 750, "is_hero": true},
		{"id": "baron", "name": "Baron Salt ★", "cost": 700, "is_hero": true},
		{"id": "pebble", "name": "Sister Pebble ★", "cost": 900, "is_hero": true}
	])
	
	for c in cats_to_show:
		var btn = Button.new()
		var price = sim.economy.calculate_price(c["cost"])
		btn.text = "%s\n%d" % [c["name"], price]
		btn.custom_minimum_size = Vector2(108, 72)
		btn.icon = _get_single_frame_icon(cat_sprites.get(c["id"]))
		btn.expand_icon = true
		btn.add_theme_constant_override("icon_max_width", 42)
		if c["is_hero"]:
			btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		btn.pressed.connect(_on_dock_button_pressed.bind(c["id"], c["is_hero"]))
		cat_buttons_container.add_child(btn)

	var scroll_node: ScrollContainer = $CanvasLayer/HUD/BottomDock/Scroll
	if not scroll_node.gui_input.is_connected(_on_dock_scroll_input):
		scroll_node.gui_input.connect(_on_dock_scroll_input)

func _on_dock_scroll_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		var scroll_node: ScrollContainer = $CanvasLayer/HUD/BottomDock/Scroll
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			scroll_node.scroll_horizontal = mini(int(scroll_node.get_h_scroll_bar().max_value), scroll_node.scroll_horizontal + 70)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			scroll_node.scroll_horizontal = maxi(0, scroll_node.scroll_horizontal - 70)

func _connect_ui_signals() -> void:
	if not start_round_btn.pressed.is_connected(_on_start_round_pressed):
		start_round_btn.pressed.connect(_on_start_round_pressed)
		speed1_btn.pressed.connect(func(): _set_speed(1))
		speed2_btn.pressed.connect(func(): _set_speed(2))
		speed3_btn.pressed.connect(func(): _set_speed(3))
		
		target_priority_btn.pressed.connect(_on_cycle_target_priority)
		brew_target_btn.pressed.connect(_on_brew_target_pressed)
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

func _setup_extended_ui() -> void:
	# Persistent Hero Commander Panel (Bottom-Left above Dock)
	hero_commander_panel = PanelContainer.new()
	hero_commander_panel.name = "HeroCommanderPanel"
	hero_commander_panel.offset_left = 16.0
	hero_commander_panel.offset_top = 485.0
	hero_commander_panel.offset_right = 360.0
	hero_commander_panel.offset_bottom = 600.0
	$CanvasLayer/HUD.add_child(hero_commander_panel)
	
	var hero_vbox := VBoxContainer.new()
	hero_vbox.add_theme_constant_override("separation", 6)
	hero_commander_panel.add_child(hero_vbox)
	
	var hero_top_hbox := HBoxContainer.new()
	hero_top_hbox.add_theme_constant_override("separation", 8)
	hero_vbox.add_child(hero_top_hbox)
	
	hero_cmd_portrait = TextureRect.new()
	hero_cmd_portrait.custom_minimum_size = Vector2(40, 40)
	hero_cmd_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero_cmd_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero_top_hbox.add_child(hero_cmd_portrait)
	
	var hero_info_vbox := VBoxContainer.new()
	hero_info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero_info_vbox.add_theme_constant_override("separation", 2)
	hero_top_hbox.add_child(hero_info_vbox)
	
	hero_cmd_name_lbl = Label.new()
	hero_cmd_name_lbl.text = "Hero: Not Deployed"
	hero_cmd_name_lbl.add_theme_font_size_override("font_size", 14)
	hero_info_vbox.add_child(hero_cmd_name_lbl)
	
	hero_cmd_xp_bar = ProgressBar.new()
	hero_cmd_xp_bar.custom_minimum_size = Vector2(0, 10)
	hero_cmd_xp_bar.show_percentage = false
	hero_info_vbox.add_child(hero_cmd_xp_bar)
	
	var hero_btn_hbox := HBoxContainer.new()
	hero_btn_hbox.add_theme_constant_override("separation", 6)
	hero_vbox.add_child(hero_btn_hbox)
	
	hero_cmd_ability1_btn = Button.new()
	hero_cmd_ability1_btn.text = "[Q] Ability 1"
	hero_cmd_ability1_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero_cmd_ability1_btn.custom_minimum_size = Vector2(0, 36)
	hero_cmd_ability1_btn.disabled = true
	hero_cmd_ability1_btn.pressed.connect(func(): _trigger_hero_ability(1))
	hero_btn_hbox.add_child(hero_cmd_ability1_btn)
	
	hero_cmd_ability2_btn = Button.new()
	hero_cmd_ability2_btn.text = "[E] Ability 2"
	hero_cmd_ability2_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero_cmd_ability2_btn.custom_minimum_size = Vector2(0, 36)
	hero_cmd_ability2_btn.disabled = true
	hero_cmd_ability2_btn.pressed.connect(func(): _trigger_hero_ability(2))
	hero_btn_hbox.add_child(hero_cmd_ability2_btn)

	# Combat Tricks Row (Equipped Actives)
	trick_buttons.clear()
	trick_btn_hbox = HBoxContainer.new()
	trick_btn_hbox.add_theme_constant_override("separation", 6)
	hero_vbox.add_child(trick_btn_hbox)

	var default_tricks = ["tuna_strike", "night_lantern", "catnip_frenzy"]
	for tid in default_tricks:
		var btn = Button.new()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 30)
		btn.pressed.connect(_on_trick_button_pressed.bind(tid))
		trick_btn_hbox.add_child(btn)
		trick_buttons.append(btn)
	
	# Results Modal (Defeat / Victory)
	results_modal = PanelContainer.new()
	results_modal.name = "ResultsModal"
	results_modal.offset_left = 300.0
	results_modal.offset_top = 80.0
	results_modal.offset_right = 980.0
	results_modal.offset_bottom = 640.0
	results_modal.visible = false
	$CanvasLayer/HUD.add_child(results_modal)
	
	var res_vbox := VBoxContainer.new()
	res_vbox.add_theme_constant_override("separation", 10)
	results_modal.add_child(res_vbox)
	
	results_title_lbl = Label.new()
	results_title_lbl.text = "Match Result"
	results_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	results_title_lbl.add_theme_font_size_override("font_size", 22)
	res_vbox.add_child(results_title_lbl)
	
	var sep1 := HSeparator.new()
	res_vbox.add_child(sep1)
	
	results_stats_lbl = Label.new()
	results_stats_lbl.text = "Rounds survived: 0"
	results_stats_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	results_stats_lbl.add_theme_font_size_override("font_size", 14)
	res_vbox.add_child(results_stats_lbl)
	
	results_leak_lbl = Label.new()
	results_leak_lbl.text = "Leaked: None"
	results_leak_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	results_leak_lbl.add_theme_font_size_override("font_size", 13)
	res_vbox.add_child(results_leak_lbl)
	
	results_immunity_lbl = Label.new()
	results_immunity_lbl.text = "Deflections: None"
	results_immunity_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	results_immunity_lbl.add_theme_font_size_override("font_size", 13)
	res_vbox.add_child(results_immunity_lbl)
	
	results_coaching_lbl = Label.new()
	results_coaching_lbl.text = "Tactical Observation: ..."
	results_coaching_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	results_coaching_lbl.add_theme_font_size_override("font_size", 13)
	results_coaching_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	res_vbox.add_child(results_coaching_lbl)
	
	results_unlock_lbl = Label.new()
	results_unlock_lbl.text = "Mastery & Progression: ..."
	results_unlock_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	results_unlock_lbl.add_theme_font_size_override("font_size", 13)
	res_vbox.add_child(results_unlock_lbl)
	
	var sep2 := HSeparator.new()
	res_vbox.add_child(sep2)
	
	var res_btn_hbox := HBoxContainer.new()
	res_btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	res_btn_hbox.add_theme_constant_override("separation", 18)
	res_vbox.add_child(res_btn_hbox)
	
	results_retry_btn = Button.new()
	results_retry_btn.text = "🔄 Retry Match"
	results_retry_btn.custom_minimum_size = Vector2(160, 42)
	results_retry_btn.pressed.connect(_on_results_retry)
	res_btn_hbox.add_child(results_retry_btn)
	
	results_map_btn = Button.new()
	results_map_btn.text = "🗺️ Map Select / Next"
	results_map_btn.custom_minimum_size = Vector2(160, 42)
	results_map_btn.pressed.connect(_on_results_map_select)
	res_btn_hbox.add_child(results_map_btn)

	var results_lead_btn := Button.new()
	results_lead_btn.text = "🏆 Top 100"
	results_lead_btn.custom_minimum_size = Vector2(140, 42)
	results_lead_btn.pressed.connect(_open_leaderboard)
	res_btn_hbox.add_child(results_lead_btn)

	_setup_obstacle_card()

func _setup_obstacle_card() -> void:
	obstacle_card = PanelContainer.new()
	obstacle_card.name = "ObstacleCard"
	obstacle_card.offset_left = 690.0
	obstacle_card.offset_top = 476.0
	obstacle_card.offset_right = 960.0
	obstacle_card.offset_bottom = 592.0
	obstacle_card.visible = false
	$CanvasLayer/HUD.add_child(obstacle_card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	obstacle_card.add_child(box)
	obstacle_card_label = Label.new()
	obstacle_card_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(obstacle_card_label)
	var buttons := HBoxContainer.new()
	box.add_child(buttons)
	obstacle_clear_btn = Button.new()
	obstacle_clear_btn.text = "Clear"
	obstacle_clear_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	obstacle_clear_btn.pressed.connect(_on_clear_obstacle_pressed)
	buttons.add_child(obstacle_clear_btn)
	var cancel := Button.new()
	cancel.text = "Close"
	cancel.pressed.connect(func(): obstacle_card.visible = false)
	buttons.add_child(cancel)

func _open_obstacle_card(obstacle: Dictionary) -> void:
	if obstacle_card == null:
		return
	selected_obstacle_id = str(obstacle.get("id", ""))
	var price := int(obstacle.get("cost", 0))
	var check := sim.can_clear_obstacle(selected_obstacle_id)
	obstacle_card_label.text = "Clear this %s to free its outlined cat pad.\nFixed cost: %d Kibble\n%s" % [str(obstacle.get("style", "clutter")), price, str(check.get("reason", ""))]
	obstacle_clear_btn.text = "Clear — %d Kibble" % price
	obstacle_clear_btn.disabled = not check.get("allowed", false)
	obstacle_card.visible = true

func _on_clear_obstacle_pressed() -> void:
	if selected_obstacle_id.is_empty() or sim == null:
		return
	if sim.clear_obstacle(selected_obstacle_id):
		combat_vfx.note({"type": "pop", "x": mouse_pos.x, "y": mouse_pos.y})
		obstacle_card.visible = false
		selected_obstacle_id = ""
		_update_ui()
	else:
		var obstacle := sim.get_obstacle_at(mouse_pos)
		if not obstacle.is_empty():
			_open_obstacle_card(obstacle)

func _update_hero_commander_panel() -> void:
	if hero_commander_panel == null:
		return

	# Update equipped combat trick buttons
	var default_tricks = ["tuna_strike", "night_lantern", "catnip_frenzy"]
	var tnames = {"tuna_strike": "🐟 Tuna", "night_lantern": "🏮 Lantern", "catnip_frenzy": "🌿 Catnip"}
	var limit = mini(trick_buttons.size(), default_tricks.size())
	for i in range(limit):
		var btn = trick_buttons[i]
		var tid = default_tricks[i]
		var tdata: Dictionary = sim.tricks_data.get("tricks", {}).get(tid, {}) if sim else {}
		var cost = int(tdata.get("kibble_cost", 50))
		var cd = int(sim.trick_cooldowns.get(tid, 0)) if sim else 0
		if sim != null and sim.mode == SimConstants.GameMode.BARE_PAW:
			btn.text = "%s (Locked)" % tnames[tid]
			btn.disabled = true
		elif cd > 0:
			btn.text = "%s (%dr)" % [tnames[tid], cd]
			btn.disabled = true
		else:
			btn.text = "%s (%d)" % [tnames[tid], cost]
			btn.disabled = (sim == null) or not sim.economy.can_afford(cost) or not sim.round_in_progress

	if sim == null or sim.hero == null:
		hero_cmd_portrait.texture = null
		hero_cmd_name_lbl.text = "Hero: Not Deployed"
		hero_cmd_xp_bar.max_value = 1.0
		hero_cmd_xp_bar.value = 0.0
		hero_cmd_ability1_btn.text = "[Q] Ability 1"
		hero_cmd_ability1_btn.disabled = true
		hero_cmd_ability2_btn.text = "[E] Ability 2"
		hero_cmd_ability2_btn.disabled = true
		return
		
	var h = sim.hero
	hero_cmd_portrait.texture = _get_single_frame_icon(cat_sprites.get(h.id))
	hero_cmd_name_lbl.text = "%s (Lvl %d)" % [h.hero_name, h.level]
	var next_xp = SimHero.XP_TABLE[mini(h.level, SimHero.XP_TABLE.size() - 1)]
	hero_cmd_xp_bar.max_value = maxf(1.0, float(next_xp))
	hero_cmd_xp_bar.value = float(h.xp)
	
	var ab1: Dictionary = h.hero_data.get("active_abilities", {}).get("ability_1", {})
	var ab1_name: String = ab1.get("name", "Ability 1")
	if h.level < 3:
		hero_cmd_ability1_btn.text = "[Q] %s (Lvl 3)" % ab1_name
		hero_cmd_ability1_btn.disabled = true
	elif h.ability_1_cooldown_left > 0.0:
		hero_cmd_ability1_btn.text = "[Q] %.1fs" % h.ability_1_cooldown_left
		hero_cmd_ability1_btn.disabled = true
	else:
		hero_cmd_ability1_btn.text = "[Q] %s" % ab1_name
		hero_cmd_ability1_btn.disabled = false
		
	var ab2: Dictionary = h.hero_data.get("active_abilities", {}).get("ability_2", {})
	var ab2_name: String = ab2.get("name", "Ability 2")
	if h.level < 10:
		hero_cmd_ability2_btn.text = "[E] %s (Lvl 10)" % ab2_name
		hero_cmd_ability2_btn.disabled = true
	elif h.ability_2_cooldown_left > 0.0:
		hero_cmd_ability2_btn.text = "[E] %.1fs" % h.ability_2_cooldown_left
		hero_cmd_ability2_btn.disabled = true
	else:
		hero_cmd_ability2_btn.text = "[E] %s" % ab2_name
		hero_cmd_ability2_btn.disabled = false

func _on_trick_button_pressed(trick_id: String) -> void:
	if sim == null or not sim.round_in_progress:
		return
	var target_world_pos = _screen_to_world(Vector2(640, 360))
	var res = sim.use_trick(trick_id, target_world_pos)
	if res.get("success", false):
		presentation_audio.note({"type": "fire", "cat": "biscuit" if trick_id == "tuna_strike" else "miso"})
		_update_ui()

func _show_results_dialog(won: bool) -> void:
	if results_modal == null or sim == null:
		return
	results_modal.visible = true
	if won:
		results_title_lbl.text = "🏆 VICTORY — Alley Cleared!"
		results_title_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	else:
		results_title_lbl.text = "💀 DEFEAT — Alley Overrun!"
		results_title_lbl.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
		
	results_stats_lbl.text = "Rounds Cleared: %d / %d | Remaining Lives: %d | Peak Kibble: %d" % [
		sim.current_round, sim.max_rounds, sim.lives, sim.peak_kibble
	]
	
	if sim.leak_history.is_empty():
		results_leak_lbl.text = "Leaked: None (Clean sheet! No lives lost)"
	else:
		var counts := {}
		var total_rbe_lost := 0
		for item in sim.leak_history:
			var u_type: String = item.get("unit_type", "mouse")
			counts[u_type] = counts.get(u_type, 0) + 1
			total_rbe_lost += int(item.get("rbe", 1))
		var leak_chunks: Array[String] = []
		for k in counts.keys():
			leak_chunks.append("%s x%d" % [k.capitalize(), counts[k]])
		results_leak_lbl.text = "Leaked (%d lives lost): %s" % [total_rbe_lost, ", ".join(leak_chunks)]
		
	if sim.blocked_immunity_counts.is_empty():
		results_immunity_lbl.text = "Deflections: None (All damage connected)"
	else:
		var imm_chunks: Array[String] = []
		for k in sim.blocked_immunity_counts.keys():
			imm_chunks.append("%s deflected: %d attacks" % [k.capitalize(), sim.blocked_immunity_counts[k]])
		results_immunity_lbl.text = "Deflected Attacks: " + ", ".join(imm_chunks)
		
	var coaching := ""
	if won:
		coaching = "Tactical Observation: Flawless clowder synergy! All alley threats countered efficiently."
	else:
		if sim.blocked_immunity_counts.get("iron", 0) > 10:
			coaching = "Tactical Observation: Iron coats deflected your Claw attacks! Deploy Bite (Pudding C, Biscuit), Blast, or Magic (Nim) against Iron."
		elif sim.blocked_immunity_counts.get("soot", 0) > 10:
			coaching = "Tactical Observation: Soot coats absorbed explosions! Use Claw, Bite, or Magic against Soot instead of Blast."
		elif sim.blocked_immunity_counts.get("ink", 0) > 10:
			coaching = "Tactical Observation: Ink coats neutralized Magic attacks! Use physical Claw or Bite cats."
		elif sim.blocked_immunity_counts.get("matriarch", 0) > 0:
			coaching = "Tactical Observation: Rat Matriarch ignores all stuns, slows, and freezes! Focus on raw single-target DPS and pop overflow."
		elif sim.blocked_immunity_counts.get("frost", 0) > 0:
			coaching = "Tactical Observation: Frost coats ignore freeze and chill! Rely on direct damage rather than crowd control."
		else:
			var leaked_types: Array = sim.leak_history.map(func(l): return str(l.get("unit_type", "")))
			if "burrow" in leaked_types or "bristle" in leaked_types or "monarch" in leaked_types:
				coaching = "Tactical Observation: High-HP Rats broke through! Add heavy single-target cats like Biscuit or Sable with high pierce."
			elif "porcelain" in leaked_types or "prism" in leaked_types:
				coaching = "Tactical Observation: High-speed swarm broke through! Nibs (dense crowds) and rapid-fire Pip help contain fast runners."
			else:
				coaching = "Tactical Observation: Review tower placement and crosspath synergies. Combine crowd-control (Pudding) with DPS (Pip, Biscuit)."
	results_coaching_lbl.text = coaching

	var crawl_reward: Dictionary = {}
	if alley_crawl_session != null and alley_crawl != null:
		if won:
			alley_crawl_session.finish_district(sim)
			if alley_crawl.completed:
				crawl_reward = save_mgr.claim_alley_crawl_completion(alley_crawl.to_dict(), alley_crawl_config)
		else:
			alley_crawl.fail_run()
		_persist_alley_crawl()
	
	# Record match completion in persistent save manager
	var fielded_cat_damages := {}
	for t in sim.towers:
		fielded_cat_damages[t.blueprint_id] = fielded_cat_damages.get(t.blueprint_id, 0) + t.damage_dealt

	var levels_data = _load_json("res://content/levels.json")
	var match_res: Dictionary = {}
	if save_mgr != null and testing_lab == null and alley_crawl_session == null:
		match_res = save_mgr.record_match_completion(
			current_map_id,
			sim.mode,
			sim.current_round,
			won,
			fielded_cat_damages,
			levels_data,
			0
		)
		_update_profile_badge()

	# Record match in Leaderboard Manager
	var lead_res: Dictionary = {}
	if lead_mgr != null and testing_lab == null and alley_crawl_session == null:
		var hero_id = sim.hero.id if sim.hero != null else "mittens"
		var clean_sheet = sim.leak_history.is_empty()
		var p_name = str(save_mgr.data.get("account", {}).get("keeper_name", "AlleyKeeper"))
		var map_data = _load_json("res://content/maps/%s.json" % current_map_id)
		var diff = str(map_data.get("difficulty", "beginner"))
		lead_res = lead_mgr.record_match(
			p_name,
			current_map_id,
			diff,
			sim.mode,
			sim.current_round,
			sim.max_rounds,
			sim.lives,
			sim.peak_kibble,
			won,
			hero_id,
			clean_sheet
		)

	var unlock_lines: Array[String] = []
	if not lead_res.is_empty():
		unlock_lines.append("🏆 Leaderboard Score: %d pts (Rank: #%d)" % [
			lead_res.get("score", 0),
			lead_res.get("rank", 99)
		])
	if not match_res.is_empty():
		unlock_lines.append("Progression: +%d Account XP (Account Level: %d)" % [
			match_res.get("account_xp_gained", 0),
			match_res.get("new_level", 1)
		])
		if match_res.get("levels_gained", 0) > 0:
			unlock_lines.append("🎉 LEVEL UP! Reached Level %d (+%d Insight Points, +%d Fishcoin)!" % [
				match_res.get("new_level", 1),
				match_res.get("levels_gained", 0),
				match_res.get("levels_gained", 0) * 15
			])
		var rewards_parts: Array[String] = []
		if match_res.get("fishcoin_gained", 0) > 0:
			rewards_parts.append("+%d Fishcoin 🐟" % match_res["fishcoin_gained"])
		if match_res.get("golden_bones_gained", 0) > 0:
			rewards_parts.append("+%d Golden Bones 🦴 (Prestige!)" % match_res["golden_bones_gained"])
		if not rewards_parts.is_empty():
			unlock_lines.append("Rewards Earned: " + ", ".join(rewards_parts))

		var revealed: Dictionary = match_res.get("revealed_unlocks", {})
		var unl_parts: Array[String] = []
		for c in revealed.get("cats", []):
			unl_parts.append("Cat: %s" % c.capitalize())
		for h in revealed.get("heroes", []):
			unl_parts.append("Hero: %s" % h.capitalize())
		for m in revealed.get("maps", []):
			unl_parts.append("Map: %s" % m.capitalize())
		if not unl_parts.is_empty():
			unlock_lines.append("✨ Unlocked: " + ", ".join(unl_parts))

	if testing_lab != null:
		results_unlock_lbl.text = "Testing Lab: no progression or rewards recorded."
	elif alley_crawl_session != null:
		if alley_crawl.completed:
			results_unlock_lbl.text = "Alley Crawl complete: +%d Fishcoin%s" % [int(crawl_reward.get("fishcoin", 0)), "" if crawl_reward.get("success", false) else " (already claimed)"]
			results_retry_btn.text = "Begin New Crawl"
		elif alley_crawl.failed:
			results_unlock_lbl.text = "Alley Crawl ended. No completion reward was granted."
			results_retry_btn.text = "Begin New Crawl"
		else:
			results_unlock_lbl.text = "District cleared. Choose a Relic and the next route."
			results_modal.visible = false
			_refresh_alley_crawl_panel(true)
	elif unlock_lines.is_empty():
		results_unlock_lbl.text = "Mastery & Progression: +%d Match XP recorded." % (sim.current_round * 25)
	else:
		results_unlock_lbl.text = "\n".join(unlock_lines)

func _setup_profile_badge() -> void:
	profile_badge_lbl = null

func _update_profile_badge() -> void:
	if profile_badge_lbl == null or save_mgr == null:
		return
	var lvl: int = int(save_mgr.data.get("account", {}).get("level", 1))
	var fish: int = int(save_mgr.data.get("economy", {}).get("fishcoin", 0))
	var bones: int = int(save_mgr.data.get("economy", {}).get("golden_bones", 0))
	profile_badge_lbl.text = "Lvl %d | 🐟 %d | 🦴 %d" % [lvl, fish, bones]

func _setup_mode_select() -> void:
	mode_select_btn = OptionButton.new()
	mode_select_btn.fit_to_longest_item = false
	mode_select_btn.custom_minimum_size = Vector2(80, 0)
	mode_select_btn.add_item("Sunny", SimConstants.GameMode.SUNNY)
	mode_select_btn.add_item("Alley", SimConstants.GameMode.ALLEY)
	mode_select_btn.add_item("Night", SimConstants.GameMode.NIGHT)
	mode_select_btn.add_item("Last Whisker", SimConstants.GameMode.LAST_WHISKER)
	mode_select_btn.add_item("Bare Paw", SimConstants.GameMode.BARE_PAW)
	mode_select_btn.add_item("Lab", TESTING_LAB_MODE)
	mode_select_btn.add_item("Crawl", ALLEY_CRAWL_MODE)
	mode_select_btn.selected = current_mode
	mode_select_btn.item_selected.connect(_on_mode_selected)
	$CanvasLayer/HUD/TopBar/HBox.add_child(mode_select_btn)

func _on_mode_selected(idx: int) -> void:
	current_mode = mode_select_btn.get_item_id(idx)
	_on_results_retry()

func _ensure_alley_crawl_run(force_new: bool = false, explicit_seed: int = -1) -> void:
	alley_crawl_config = _load_json("res://content/grand_expansion/alley_crawl.json")
	var restored := false
	if not force_new and save_mgr != null:
		var stored := save_mgr.get_alley_crawl_run()
		if not stored.is_empty():
			var candidate := SimAlleyCrawl.new()
			if candidate.load_from_dict(stored, alley_crawl_config) and not candidate.completed and not candidate.failed:
				alley_crawl = candidate
				restored = true
	if not restored:
		alley_crawl = SimAlleyCrawl.new()
		var run_seed := explicit_seed if explicit_seed >= 0 else int(Time.get_unix_time_from_system())
		alley_crawl.setup(run_seed, alley_crawl_config)
		_persist_alley_crawl()

func _persist_alley_crawl() -> void:
	if save_mgr == null or alley_crawl == null:
		return
	save_mgr.store_alley_crawl_run(alley_crawl.to_dict())
	save_mgr.save_profile()

func _setup_alley_crawl_panel() -> void:
	crawl_panel = PanelContainer.new()
	crawl_panel.position = Vector2(250, 105)
	crawl_panel.custom_minimum_size = Vector2(780, 440)
	$CanvasLayer/HUD.add_child(crawl_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	crawl_panel.add_child(box)
	crawl_title = Label.new()
	crawl_title.add_theme_font_size_override("font_size", 26)
	crawl_title.text = "Alley Crawl"
	box.add_child(crawl_title)
	crawl_details = Label.new()
	crawl_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	crawl_details.custom_minimum_size = Vector2(740, 95)
	box.add_child(crawl_details)
	var relic_heading := Label.new()
	relic_heading.text = "Choose one Relic"
	box.add_child(relic_heading)
	crawl_relic_box = HBoxContainer.new()
	crawl_relic_box.add_theme_constant_override("separation", 8)
	box.add_child(crawl_relic_box)
	crawl_take_curse = CheckButton.new()
	crawl_take_curse.text = "Accept the shown Risk Curse for completion Fishcoin"
	box.add_child(crawl_take_curse)
	var next_heading := Label.new()
	next_heading.text = "Choose the next district"
	box.add_child(next_heading)
	crawl_next_box = HBoxContainer.new()
	crawl_next_box.add_theme_constant_override("separation", 8)
	box.add_child(crawl_next_box)
	var close := Button.new()
	close.text = "Review later"
	close.pressed.connect(func(): crawl_panel.visible = false)
	box.add_child(close)
	crawl_panel.visible = false

func _clear_control_children(container: Control) -> void:
	for child in container.get_children():
		child.queue_free()

func _signed_value(value: float) -> String:
	return ("+" if value >= 0.0 else "") + str(value)

func _refresh_alley_crawl_panel(show_panel: bool = true) -> void:
	if crawl_panel == null:
		return
	if current_mode != ALLEY_CRAWL_MODE or alley_crawl == null:
		crawl_panel.visible = false
		return
	var node := alley_crawl.get_current_node()
	var modifier_names: Array[String] = []
	for modifier_id in node.get("modifiers", []):
		modifier_names.append(str(alley_crawl_config.get("modifiers", {}).get(modifier_id, {}).get("name", modifier_id)))
	crawl_title.text = "Alley Crawl — District %d of %d" % [alley_crawl.current_stage + 1, alley_crawl.stage_count]
	crawl_details.text = "Map: %s\nModifiers: %s\nBanked starter Kibble: %d\nRelics: %s\nCurses: %s" % [
		str(node.get("map_id", "")).capitalize(),
		"None" if modifier_names.is_empty() else ", ".join(modifier_names),
		alley_crawl.banked_kibble,
		"None" if alley_crawl.relics.is_empty() else ", ".join(alley_crawl.relics),
		"None" if alley_crawl.curses.is_empty() else ", ".join(alley_crawl.curses)
	]
	_clear_control_children(crawl_relic_box)
	for relic_id in alley_crawl.pending_relic_offer:
		var definition: Dictionary = alley_crawl_config.get("relics", {}).get(relic_id, {})
		var button := Button.new()
		button.custom_minimum_size = Vector2(225, 70)
		button.text = "%s\n%s %s" % [definition.get("name", relic_id), definition.get("effect", "effect"), _signed_value(float(definition.get("value", 0.0)))]
		button.pressed.connect(_choose_crawl_relic.bind(relic_id))
		crawl_relic_box.add_child(button)
	crawl_take_curse.visible = not alley_crawl.pending_curse_offer.is_empty() and not alley_crawl.pending_relic_offer.is_empty()
	if crawl_take_curse.visible:
		var curse: Dictionary = alley_crawl_config.get("curses", {}).get(alley_crawl.pending_curse_offer, {})
		crawl_take_curse.text = "Accept %s (%s %s) for +%d Fishcoin on completion" % [curse.get("name", "Risk Curse"), curse.get("effect", "effect"), _signed_value(float(curse.get("value", 0.0))), int(curse.get("fishcoin", 0))]
		crawl_take_curse.set_pressed_no_signal(false)
	_clear_control_children(crawl_next_box)
	if alley_crawl.pending_relic_offer.is_empty() and not alley_crawl.completed:
		for next_node in alley_crawl.get_next_nodes():
			var button := Button.new()
			button.custom_minimum_size = Vector2(260, 64)
			button.text = "%s\n%s" % [str(next_node.get("map_id", "")).capitalize(), ", ".join(next_node.get("modifiers", []))]
			button.pressed.connect(_choose_crawl_node.bind(str(next_node.id)))
			crawl_next_box.add_child(button)
	if show_panel:
		crawl_panel.visible = true

func _choose_crawl_relic(relic_id: String) -> void:
	if alley_crawl != null and alley_crawl.choose_relic(relic_id, crawl_take_curse.button_pressed):
		_persist_alley_crawl()
		_refresh_alley_crawl_panel()

func _choose_crawl_node(node_id: String) -> void:
	if alley_crawl != null and alley_crawl.choose_next_node(node_id):
		_persist_alley_crawl()
		crawl_panel.visible = false
		_init_simulation()
		_update_ui()

func _setup_testing_lab_controls() -> void:
	lab_panel = PanelContainer.new()
	lab_panel.position = Vector2(12, 104)
	lab_panel.custom_minimum_size = Vector2(195, 0)
	$CanvasLayer/HUD.add_child(lab_panel)
	var box := VBoxContainer.new()
	lab_panel.add_child(box)
	var title := Label.new()
	title.text = "Testing Lab (no rewards)"
	box.add_child(title)
	var unlimited := CheckButton.new()
	unlimited.text = "Unlimited Kibble"
	unlimited.toggled.connect(func(value: bool):
		if testing_lab != null:
			testing_lab.set_unlimited_kibble(value)
	)
	box.add_child(unlimited)
	var pause := CheckButton.new()
	pause.text = "Freeze simulation"
	pause.toggled.connect(func(value: bool):
		if testing_lab != null:
			testing_lab.set_paused(value)
	)
	box.add_child(pause)
	var step_btn := Button.new()
	step_btn.text = "Step one tick"
	step_btn.pressed.connect(func():
		if testing_lab != null:
			_lab_message("Advanced one tick" if testing_lab.step() else "Freeze the simulation first")
	)
	box.add_child(step_btn)
	lab_round = SpinBox.new()
	lab_round.min_value = 1
	lab_round.max_value = 100
	lab_round.step = 1
	lab_round.value = 1
	lab_round.tooltip_text = "Authored round number"
	box.add_child(lab_round)
	var round_btn := Button.new()
	round_btn.text = "Start selected round"
	round_btn.pressed.connect(func():
		if testing_lab != null:
			_lab_message("Round started" if testing_lab.start_round(int(lab_round.value)) else "Round unavailable or already active")
	)
	box.add_child(round_btn)
	lab_enemy = OptionButton.new()
	box.add_child(lab_enemy)
	lab_path = OptionButton.new()
	box.add_child(lab_path)
	var spawn := Button.new()
	spawn.text = "Spawn enemy"
	spawn.pressed.connect(func():
		if testing_lab != null and lab_enemy.selected >= 0 and lab_path.selected >= 0:
			var item: Dictionary = lab_enemy.get_item_metadata(lab_enemy.selected)
			_lab_message("Enemy spawned" if testing_lab.spawn_enemy(item.kind, item.id, lab_path.selected) else "Enemy could not be spawned")
	)
	box.add_child(spawn)
	var dps_reset := Button.new()
	dps_reset.text = "Reset DPS sample"
	dps_reset.pressed.connect(func():
		if testing_lab != null:
			testing_lab.reset_dps_sample()
	)
	box.add_child(dps_reset)
	lab_dps_label = Label.new()
	lab_dps_label.text = "DPS: unavailable (0 ticks)"
	box.add_child(lab_dps_label)
	for overlay in [
		{"label": "Show Land mask", "kind": "land"},
		{"label": "Show Water mask", "kind": "water"},
		{"label": "Show Perch mask", "kind": "perch"},
		{"label": "Show Blockers", "kind": "blocker"},
		{"label": "Show Path ribbon", "kind": "path"}
	]:
		var toggle := CheckButton.new()
		toggle.text = overlay.label
		toggle.toggled.connect(_set_lab_overlay.bind(str(overlay.kind)))
		box.add_child(toggle)
	lab_status = Label.new()
	lab_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(lab_status)
	_refresh_testing_lab_controls()

func _lab_message(message: String) -> void:
	if lab_status != null:
		lab_status.text = message

func _set_lab_overlay(enabled: bool, kind: String) -> void:
	match kind:
		"land": lab_overlay_land = enabled
		"water": lab_overlay_water = enabled
		"perch": lab_overlay_perch = enabled
		"blocker": lab_overlay_blocker = enabled
		"path": lab_overlay_path = enabled
	queue_redraw()

func _refresh_testing_lab_controls() -> void:
	if lab_panel == null:
		return
	lab_panel.visible = testing_lab != null
	if testing_lab == null:
		return
	# Rebuild controls on every new lab match so no stale setting is shown.
	for child in lab_panel.get_child(0).get_children():
		if child is CheckButton:
			child.set_pressed_no_signal(false)
	lab_overlay_land = false
	lab_overlay_water = false
	lab_overlay_perch = false
	lab_overlay_blocker = false
	lab_overlay_path = false
	lab_round.max_value = sim.max_rounds
	lab_round.value = 1
	lab_enemy.clear()
	for kind in ["mouse", "rat"]:
		var entries: Dictionary = sim.mice_data.get("coats", {}) if kind == "mouse" else sim.rats_data.get("rats", {})
		var ids: Array = entries.keys()
		ids.sort()
		for id in ids:
			lab_enemy.add_item("%s: %s" % [kind.capitalize(), str(id).capitalize()])
			lab_enemy.set_item_metadata(lab_enemy.item_count - 1, {"kind": kind, "id": str(id)})
	lab_path.clear()
	for i in range(sim.paths.size()):
		lab_path.add_item("Path %d: %s" % [i + 1, str(sim.paths[i].get("id", ""))])
	_lab_message("Lab sessions do not grant rewards.")

func _setup_top_bar_extra_buttons() -> void:
	auto_wave_btn = Button.new()
	_update_auto_wave_btn_text()
	auto_wave_btn.custom_minimum_size = Vector2(70, 0)
	auto_wave_btn.tooltip_text = "Auto-Start Waves (0.4s pause)"
	auto_wave_btn.pressed.connect(_toggle_auto_wave)
	$CanvasLayer/HUD/TopBar/HBox.add_child(auto_wave_btn)

	coop_player_toggle_btn = Button.new()
	coop_player_toggle_btn.text = "🐱 P1"
	coop_player_toggle_btn.custom_minimum_size = Vector2(50, 0)
	coop_player_toggle_btn.tooltip_text = "Switch Co-op Placer [Hotkey: P]"
	coop_player_toggle_btn.visible = false
	coop_player_toggle_btn.pressed.connect(_toggle_coop_player)
	$CanvasLayer/HUD/TopBar/HBox.add_child(coop_player_toggle_btn)

	almanac_top_btn = Button.new()
	almanac_top_btn.text = "📖"
	almanac_top_btn.custom_minimum_size = Vector2(32, 0)
	almanac_top_btn.tooltip_text = "The Almanac"
	almanac_top_btn.pressed.connect(_open_almanac)
	$CanvasLayer/HUD/TopBar/HBox.add_child(almanac_top_btn)

	menu_hub_btn = Button.new()
	menu_hub_btn.text = "☰ Menu"
	menu_hub_btn.custom_minimum_size = Vector2(62, 0)
	menu_hub_btn.tooltip_text = "Game Menu (Play, Almanac, Insights, Shop, Settings, Leaderboard, Co-op)"
	menu_hub_btn.pressed.connect(_toggle_title_menu)
	$CanvasLayer/HUD/TopBar/HBox.add_child(menu_hub_btn)

func _organize_top_bar() -> void:
	var hbox: HBoxContainer = $CanvasLayer/HUD/TopBar/HBox
	var speed_container = hbox.get_node_or_null("SpeedContainer")
	var ordered: Array = [
		lives_label,
		kibble_label,
		round_label,
		map_select_btn,
		mode_select_btn,
		speed_container,
		auto_wave_btn,
		start_round_btn,
		coop_player_toggle_btn,
		almanac_top_btn,
		language_btn,
		menu_hub_btn
	]
	var idx := 0
	for node in ordered:
		if node != null and node.get_parent() == hbox:
			hbox.move_child(node, idx)
			idx += 1

func _update_auto_wave_btn_text() -> void:
	if auto_wave_btn == null:
		return
	if auto_wave_enabled:
		auto_wave_btn.text = "⚡ Auto"
		auto_wave_btn.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	else:
		auto_wave_btn.text = "⏸ Auto"
		auto_wave_btn.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))

func _toggle_auto_wave() -> void:
	auto_wave_enabled = not auto_wave_enabled
	auto_start_timer = -1.0
	if save_mgr != null:
		save_mgr.data["settings"]["auto_start"] = auto_wave_enabled
		save_mgr.save_profile()
	_update_auto_wave_btn_text()

func _open_leaderboard() -> void:
	if leaderboard_modal != null:
		leaderboard_modal.visible = true
		leaderboard_modal.refresh()

func _open_coop_modal() -> void:
	if coop_modal != null:
		coop_modal.visible = true

func _on_start_local_coop() -> void:
	coop_mode_active = true
	coop_current_player = 1
	if coop_player_toggle_btn != null:
		coop_player_toggle_btn.visible = true
		coop_player_toggle_btn.text = "🐱 P1 (Teal)"
		coop_player_toggle_btn.add_theme_color_override("font_color", Color(0.2, 0.85, 0.95))
	_on_results_retry()

func _on_start_network_coop(is_host: bool) -> void:
	coop_mode_active = true
	coop_current_player = 1 if is_host else 2
	if coop_player_toggle_btn != null:
		coop_player_toggle_btn.visible = true
		coop_player_toggle_btn.text = "🐱 %s" % ("Host (P1)" if is_host else "Client (P2)")
	_on_results_retry()

func _toggle_coop_player() -> void:
	coop_current_player = 2 if coop_current_player == 1 else 1
	if coop_player_toggle_btn != null:
		if coop_current_player == 1:
			coop_player_toggle_btn.text = "🐱 P1 (Teal)"
			coop_player_toggle_btn.add_theme_color_override("font_color", Color(0.2, 0.85, 0.95))
		else:
			coop_player_toggle_btn.text = "🐱 P2 (Orange)"
			coop_player_toggle_btn.add_theme_color_override("font_color", Color(1.0, 0.55, 0.15))

func _setup_meta_screens() -> void:
	almanac_modal = AlmanacModal.new()
	almanac_modal.setup(cat_sprites, mouse_sprites, rat_sprites)
	almanac_modal.visible = false
	$CanvasLayer/HUD.add_child(almanac_modal)

	leaderboard_modal = LeaderboardModal.new()
	leaderboard_modal.setup(lead_mgr)
	leaderboard_modal.visible = false
	$CanvasLayer/HUD.add_child(leaderboard_modal)

	coop_modal = CoopModal.new()
	coop_modal.setup(net_mgr)
	coop_modal.visible = false
	coop_modal.start_local_coop.connect(_on_start_local_coop)
	coop_modal.start_network_coop.connect(_on_start_network_coop)
	$CanvasLayer/HUD.add_child(coop_modal)

	insights_modal = InsightsModal.new()
	insights_modal.setup(save_mgr)
	insights_modal.visible = false
	$CanvasLayer/HUD.add_child(insights_modal)

	shop_modal = ShopModal.new()
	shop_modal.setup(save_mgr)
	shop_modal.visible = false
	$CanvasLayer/HUD.add_child(shop_modal)

	settings_modal = SettingsModal.new()
	settings_modal.setup(save_mgr)
	settings_modal.visible = false
	settings_modal.settings_changed.connect(_on_settings_modal_changed)
	$CanvasLayer/HUD.add_child(settings_modal)

	title_menu = TitleMenu.new()
	title_menu.setup(save_mgr)
	title_menu.visible = false
	title_menu.leaderboard_pressed.connect(_open_leaderboard)
	$CanvasLayer/HUD.add_child(title_menu)

	title_menu.play_pressed.connect(func(): _close_all_modals())
	title_menu.almanac_pressed.connect(_open_almanac)
	title_menu.insights_pressed.connect(_open_insights)
	title_menu.shop_pressed.connect(func(): _open_shop("regular"))
	title_menu.prestige_shop_pressed.connect(func(): _open_shop("vault"))
	title_menu.settings_pressed.connect(_open_settings)
	title_menu.coop_pressed.connect(_open_coop_modal)

func _close_all_modals() -> void:
	if title_menu != null: title_menu.visible = false
	if almanac_modal != null: almanac_modal.visible = false
	if insights_modal != null: insights_modal.visible = false
	if shop_modal != null: shop_modal.visible = false
	if settings_modal != null: settings_modal.visible = false

func _open_almanac() -> void:
	_close_all_modals()
	if almanac_modal != null:
		almanac_modal.visible = true

func _open_insights() -> void:
	_close_all_modals()
	if insights_modal != null:
		insights_modal.visible = true

func _open_shop(tab: String = "regular") -> void:
	_close_all_modals()
	if shop_modal != null:
		shop_modal.visible = true
		shop_modal._select_tab(tab)

func _open_settings() -> void:
	_close_all_modals()
	if settings_modal != null:
		settings_modal.visible = true

func _toggle_title_menu() -> void:
	if title_menu == null:
		return
	if title_menu.visible:
		title_menu.visible = false
	else:
		_close_all_modals()
		title_menu.update_profile_display(save_mgr)
		title_menu.visible = true

func _on_settings_modal_changed() -> void:
	if save_mgr == null:
		return
	var s: Dictionary = save_mgr.data.get("settings", {})
	if localization != null:
		var lang = str(s.get("language", "en"))
		if localization.language != lang:
			localization.setup(lang)
			_refresh_language_ui()
			_update_ui()

func _on_results_retry() -> void:
	if results_modal != null:
		results_modal.visible = false
	selected_tower = null
	selected_is_hero = false
	placing_cat_id = ""
	is_placing_hero = false
	match_paused = false
	inspector_panel.visible = false
	previous_unit_s.clear()
	if current_mode == ALLEY_CRAWL_MODE and alley_crawl != null and (alley_crawl.completed or alley_crawl.failed):
		_ensure_alley_crawl_run(true)
	_init_simulation(current_map_id)
	_update_ui()
	queue_redraw()

func _on_results_map_select() -> void:
	if results_modal != null:
		results_modal.visible = false
	if sim.match_won and map_select_btn != null and map_select_btn.item_count > 0:
		var next_idx = (map_select_btn.selected + 1) % map_select_btn.item_count
		map_select_btn.selected = next_idx
		_on_map_selected(next_idx)
	else:
		_on_results_retry()

func _setup_map_select() -> void:
	map_select_btn = OptionButton.new()
	map_select_btn.fit_to_longest_item = false
	map_select_btn.custom_minimum_size = Vector2(130, 0)
	var hbox: HBoxContainer = $CanvasLayer/HUD/TopBar/HBox
	hbox.add_child(map_select_btn)
	
	var maps_list = [
		{"id": "sunny_gutter", "name": "🟢 Sunny Gutter (B)"},
		{"id": "lantern_stoop", "name": "🟢 Lantern Stoop (B)"},
		{"id": "crabapple_bend", "name": "🟢 Crabapple Bend (B)"},
		{"id": "fishbone_straight", "name": "🟢 Fishbone Straight (B)"},
		{"id": "morning_arch", "name": "🟢 Morning Arch (B)"},
		{"id": "market_lane", "name": "🟡 Market Lane (B+)"},
		{"id": "stall_row", "name": "🟡 Stall Row (B+)"},
		{"id": "puddle_court", "name": "🟡 Puddle Court (B+)"},
		{"id": "sack_corner", "name": "🟡 Sack Corner (B+)"},
		{"id": "herring_square", "name": "🟡 Herring Square (B+)"},
		{"id": "fig_and_twine", "name": "🟡 Fig & Twine (B+)"},
		{"id": "spice_arcade", "name": "🟡 Spice Arcade (B+)"},
		{"id": "twin_gutters", "name": "🟠 Twin Gutters (I)"},
		{"id": "welcome_bridge", "name": "🟠 Welcome Bridge (I)"},
		{"id": "chimney_step", "name": "🟠 Chimney Step (I)"},
		{"id": "basket_bridge", "name": "🟠 Basket Bridge (I)"},
		{"id": "rooftop_crossing", "name": "🟠 Rooftop Crossing (I)"},
		{"id": "copper_scale", "name": "🟠 Copper Scale (I)"},
		{"id": "canopy_cross", "name": "🟠 Canopy Cross (I)"},
		{"id": "weigh_house", "name": "🟠 Weigh House (I)"},
		{"id": "two_purse_lane", "name": "🔴 Two-Purse Lane (A)"},
		{"id": "fishmarket_maze", "name": "🔴 Fishmarket Maze (A)"},
		{"id": "canal_night", "name": "🔴 Canal Night (A)"},
		{"id": "night_onion", "name": "🔴 Night Onion (A)"},
		{"id": "grand_bazaar", "name": "🔴 Grand Bazaar (A)"},
		{"id": "the_warren", "name": "🟣 The Warren (E)"}
	]
	
	for i in range(maps_list.size()):
		var m = maps_list[i]
		map_select_btn.add_item(_t("map.%s" % m.id, m.name), i)
		map_select_btn.set_item_metadata(i, m.id)
		if m.id == current_map_id:
			map_select_btn.selected = i
			
	map_select_btn.item_selected.connect(_on_map_selected)

func _setup_language_toggle() -> void:
	language_btn = Button.new()
	language_btn.custom_minimum_size = Vector2(36, 0)
	language_btn.tooltip_text = "Toggle Language (EN / UA)"
	language_btn.pressed.connect(_on_language_toggled)
	$CanvasLayer/HUD/TopBar/HBox.add_child(language_btn)
	_apply_wood_theme()
	_refresh_language_ui()

func _load_language_setting() -> String:
	var settings := ConfigFile.new()
	if settings.load("user://settings.cfg") == OK:
		return str(settings.get_value("settings", "language", "en"))
	return "en"

func _save_language_setting() -> void:
	var settings := ConfigFile.new()
	settings.set_value("settings", "language", localization.language)
	settings.save("user://settings.cfg")

func _on_language_toggled() -> void:
	localization.toggle()
	_save_language_setting()
	_refresh_language_ui()
	_update_ui()

func _refresh_language_ui() -> void:
	if language_btn != null:
		language_btn.text = localization.text("ui.language", "UA")
	if start_round_btn != null and not sim.round_in_progress:
		start_round_btn.text = localization.text("ui.start_round", "Start round")

func _t(key: String, fallback: String, replacements: Dictionary = {}) -> String:
	return localization.text(key, fallback, replacements) if localization != null else fallback

func _on_map_selected(idx: int) -> void:
	var chosen_id = map_select_btn.get_item_metadata(idx)
	selected_tower = null
	selected_is_hero = false
	placing_cat_id = ""
	is_placing_hero = false
	match_paused = false
	inspector_panel.visible = false
	previous_unit_s.clear()
	_init_simulation(chosen_id)
	_update_ui()
	queue_redraw()

func _set_speed(spd: int) -> void:
	game_speed = spd
	speed1_btn.disabled = (spd == 1)
	speed2_btn.disabled = (spd == 2)
	speed3_btn.disabled = (spd == 3)

func _physics_process(_delta: float) -> void:
	if sim == null:
		return
		
	for unit in sim.units:
		previous_unit_s[unit.id] = unit.s
	# Tick according to speed multiplier
	if not feat_modal.visible and not match_paused:
		for _i in range(game_speed):
			if testing_lab != null:
				testing_lab.advance()
			else:
				sim.tick()
	for unit in sim.units:
		if not previous_unit_s.has(unit.id):
			previous_unit_s[unit.id] = unit.s
	interpolation_alpha = 0.0
			
	# Check if round just finished and feats are pending
	if not sim.round_in_progress and not feat_modal.visible:
		_check_pending_feats()
		if auto_wave_enabled and testing_lab == null and not match_paused and not sim.match_won and not sim.match_lost and not (results_modal != null and results_modal.visible):
			if auto_start_timer < 0.0:
				auto_start_timer = auto_wave_delay
			else:
				auto_start_timer -= _delta
				if auto_start_timer <= 0.0:
					auto_start_timer = -1.0
					_on_start_round_pressed()
		else:
			auto_start_timer = -1.0
	else:
		auto_start_timer = -1.0
		
	_update_ui()
	queue_redraw()

func _process(delta: float) -> void:
	_pan_camera(delta)
	var vp := get_viewport()
	if vp != null:
		mouse_pos = _screen_to_world(vp.get_mouse_position())
	if sim == null:
		return
	interpolation_alpha = minf(1.0, interpolation_alpha + delta / maxf(0.001, get_physics_process_delta_time()))
	if actor_drawer != null:
		actor_drawer.advance(delta)
	if combat_vfx != null:
		combat_vfx.advance(delta)
	_drain_presentation_log()
	balcony_hint_time = maxf(0.0, balcony_hint_time - delta)
	queue_redraw()

func _drain_presentation_log() -> void:
	for event in sim.drain_presentation_log():
		if event.has("s") and not event.has("x"):
			var pos := sim.get_point_on_path(float(event.s), int(event.get("path_index", 0)))
			event["x"] = pos.x
			event["y"] = pos.y
		actor_drawer.note(event)
		combat_vfx.note(event)
		presentation_audio.note(event)

func _setup_balcony_camera() -> void:
	world_camera = Camera2D.new()
	world_camera.position = Vector2(640.0, 360.0)
	world_camera.zoom = Vector2.ONE
	world_camera.position_smoothing_enabled = true
	world_camera.position_smoothing_speed = 9.0
	add_child(world_camera)

func _restore_balcony_view() -> void:
	if world_camera == null:
		return
	world_camera.position = Vector2(640.0, 360.0)
	world_camera.rotation = 0.0
	world_camera.zoom = Vector2.ONE
	world_camera.reset_smoothing()
	balcony_hint_time = 0.0

func _setup_camera_controls() -> void:
	camera_panel = PanelContainer.new()
	camera_panel.name = "CameraControlsPanel"
	camera_panel.offset_left = 836.0
	camera_panel.offset_top = 568.0
	camera_panel.offset_right = 960.0
	camera_panel.offset_bottom = 604.0
	var panel_style := _wood_panel()
	panel_style.content_margin_left = 4
	panel_style.content_margin_right = 4
	panel_style.content_margin_top = 3
	panel_style.content_margin_bottom = 3
	panel_style.set_corner_radius_all(8)
	camera_panel.add_theme_stylebox_override("panel", panel_style)
	$CanvasLayer/HUD.add_child(camera_panel)

	camera_controls = HBoxContainer.new()
	camera_controls.alignment = BoxContainer.ALIGNMENT_CENTER
	camera_controls.add_theme_constant_override("separation", 4)
	camera_panel.add_child(camera_controls)

	for label in ["+", "−", "Reset"]:
		var button := Button.new()
		button.text = label
		button.custom_minimum_size = Vector2(28, 24) if label != "Reset" else Vector2(46, 24)
		button.focus_mode = Control.FOCUS_NONE
		button.tooltip_text = "Zoom in · Arrow keys: move" if label == "+" else ("Zoom out" if label == "−" else "Reset view · Home")
		if label == "Reset":
			button.pressed.connect(_restore_balcony_view)
		else:
			var factor := 1.12 if label == "+" else 1.0 / 1.12
			button.pressed.connect(func(): _zoom_camera(factor, get_viewport_rect().size * 0.5))
		camera_controls.add_child(button)

func _clamp_camera() -> void:
	# Rotated viewport extents keep every visible corner inside the backdrop.
	var half := CAMERA_SIZE * 0.5 / world_camera.zoom.x
	var angle := world_camera.rotation
	var extent := Vector2(absf(cos(angle)) * half.x + absf(sin(angle)) * half.y,
		absf(sin(angle)) * half.x + absf(cos(angle)) * half.y)
	extent = extent.min(CAMERA_SIZE * 0.5)
	world_camera.position = world_camera.position.clamp(extent, CAMERA_SIZE - extent)

func _zoom_camera(factor: float, screen_focus: Vector2) -> void:
	var next_zoom := clampf(world_camera.zoom.x * factor, 1.0, CAMERA_MAX_ZOOM)
	if is_equal_approx(next_zoom, 1.0):
		_restore_balcony_view()
		return
	var focus := _screen_to_world(screen_focus)
	world_camera.position = focus + (world_camera.position - focus) * world_camera.zoom.x / next_zoom
	world_camera.zoom = Vector2.ONE * next_zoom
	_clamp_camera()
	balcony_hint_time = 3.0

func _pan_camera(delta: float) -> void:
	if world_camera == null or world_camera.zoom.x <= 1.0 or feat_modal.visible:
		return
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	world_camera.position += direction.normalized().rotated(world_camera.rotation) * 480.0 * delta / world_camera.zoom.x
	_clamp_camera()

func _screen_to_world(screen_pos: Vector2) -> Vector2:
	return get_canvas_transform().affine_inverse() * screen_pos

func _toggle_pause() -> void:
	match_paused = not match_paused
	start_round_btn.text = _t("ui.resume", "Resume") if match_paused else _t("ui.start_round", "Start round")

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_pos = _screen_to_world(event.position)
		if world_camera != null and (event.button_mask & MOUSE_BUTTON_MASK_RIGHT) != 0:
			if event.relative.length() > 0.5:
				right_dragged = true
				world_camera.rotation = clampf(world_camera.rotation + event.relative.x * 0.003, -0.34, 0.34)
				if world_camera.zoom.x <= 1.0:
					_restore_balcony_view()
				else:
					_clamp_camera()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if world_camera != null and event.pressed and event.position.x < 970 and event.position.y > 65 and event.position.y < 600 and not feat_modal.visible:
				_zoom_camera(1.12 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.12, event.position)
			return
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				right_drag_origin = event.position
				right_dragged = false
			elif not right_dragged:
				_cancel_placement_or_selection()
			return
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_handle_left_click(event.position)
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			auto_start_timer = -1.0
			_on_start_round_pressed()
		elif event.keycode == KEY_P:
			if coop_mode_active:
				_toggle_coop_player()
		elif event.keycode == KEY_ESCAPE:
			if brew_selecting_source != null or placing_cat_id != "" or selected_tower != null or selected_is_hero:
				_cancel_placement_or_selection()
			else:
				_toggle_pause()
		elif event.keycode == KEY_HOME:
			_restore_balcony_view()
		elif event.keycode == KEY_1:
			_set_speed(1)
		elif event.keycode == KEY_2:
			_set_speed(2)
		elif event.keycode == KEY_3:
			_set_speed(3)
		elif event.keycode == KEY_Q:
			_trigger_hero_ability(1)
		elif event.keycode == KEY_E:
			_trigger_hero_ability(2)

func _handle_left_click(screen_pos: Vector2) -> void:
	if title_menu != null and title_menu.visible:
		return
	if leaderboard_modal != null and leaderboard_modal.visible and leaderboard_modal.get_global_rect().has_point(screen_pos):
		return
	if coop_modal != null and coop_modal.visible and coop_modal.get_global_rect().has_point(screen_pos):
		return
	if almanac_modal != null and almanac_modal.visible and almanac_modal.get_global_rect().has_point(screen_pos):
		return
	if insights_modal != null and insights_modal.visible and insights_modal.get_global_rect().has_point(screen_pos):
		return
	if shop_modal != null and shop_modal.visible and shop_modal.get_global_rect().has_point(screen_pos):
		return
	if settings_modal != null and settings_modal.visible and settings_modal.get_global_rect().has_point(screen_pos):
		return
	if camera_panel != null and camera_panel.visible and camera_panel.get_global_rect().has_point(screen_pos):
		return
	if camera_controls != null and camera_controls.get_global_rect().has_point(screen_pos):
		return
	if hero_commander_panel != null and hero_commander_panel.visible and hero_commander_panel.get_global_rect().has_point(screen_pos):
		return
	if results_modal != null and results_modal.visible and results_modal.get_global_rect().has_point(screen_pos):
		return
	# Ignore clicks on UI panels
	if screen_pos.y > 600 or screen_pos.x > 970 or screen_pos.y < 65:
		return
	var click_pos := _screen_to_world(screen_pos)

	if brew_selecting_source != null:
		for candidate in sim.towers:
			if click_pos.distance_to(candidate.position) <= candidate.footprint_radius + 6.0:
				if sim.assign_brew(brew_selecting_source, candidate):
					var source := brew_selecting_source
					brew_selecting_source = null
					_select_tower(source)
				else:
					brew_target_btn.text = "Invalid target — choose a cat in range"
				return
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
				var owner = coop_current_player if coop_mode_active else 1
				var t = sim.place_tower(placing_cat_id, click_pos, owner)
				if t != null:
					_select_tower(t)
					placing_cat_id = ""
		return

	# An obstacle opens an explanatory card only outside placement mode. It cannot
	# consume Kibble until the player presses the dedicated Clear button.
	var clicked_obstacle := sim.get_obstacle_at(click_pos)
	if not clicked_obstacle.is_empty():
		_open_obstacle_card(clicked_obstacle)
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
	brew_selecting_source = null
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
	brew_target_btn.visible = false

func _on_brew_target_pressed() -> void:
	if selected_tower == null or selected_tower.cat_id != "bub":
		return
	brew_selecting_source = selected_tower
	placing_cat_id = ""
	brew_target_btn.text = "Choose a cat on the map (Esc cancels)"
	queue_redraw()

func _update_inspector() -> void:
	if selected_tower != null:
		cat_title_lbl.text = "%s — %s" % [selected_tower.cat_name, selected_tower.cat_data.get("title", "Cat")]
		var mastery_text = _get_mastery_text(selected_tower.cat_id)
		cat_category_lbl.text = "%s Cat • %s Damage\n%s" % [
			selected_tower.category,
			SimConstants.damage_type_to_string(selected_tower.damage_type),
			mastery_text
		]
		
		if selected_tower.cat_id == "goldie":
			stats_lbl.text = "End-Round Income: +%d | Total Produced: %d Kibble" % [
				selected_tower.cat_data.get("base", {}).get("end_round_kibble", 140),
				selected_tower.total_kibble_produced
			]
		elif selected_tower.cat_id == "miso":
			var rad = sim._get_miso_aura_radius(selected_tower)
			stats_lbl.text = "Aura Radius: %d | Buffing: %d Cats | Assisted: %d Dmg" % [
				int(rad), selected_tower.buffed_cats_count, int(selected_tower.total_buff_damage_assisted)
			]
		else:
			var owner_info = " • P%d" % selected_tower.owner_id if coop_mode_active else ""
			stats_lbl.text = "Dmg: %d | Pierce: %d | Range: %d | CD: %.2fs%s\nPops: %d | Total Dealt: %d Dmg" % [
				selected_tower.get_effective_damage(),
				selected_tower.get_effective_pierce(),
				int(selected_tower.get_effective_range()),
				selected_tower.get_effective_cooldown(),
				owner_info,
				selected_tower.pops_count,
				selected_tower.damage_dealt
			]
			if selected_tower.cat_id == "pudding" and selected_tower.freeze_assists > 0:
				stats_lbl.text += " | Freeze Assists: %d" % selected_tower.freeze_assists
			elif selected_tower.cat_id == "bub":
				var bub_base: Dictionary = selected_tower.cat_data.get("base", {})
				var corrosion_dps := sim._cat_tier_value(selected_tower, "corrosion_dps", float(bub_base.get("corrosion_dps", 1.0)))
				var corrosion_duration := sim._cat_tier_value(selected_tower, "corrosion_duration", float(bub_base.get("corrosion_duration", 3.0))) + selected_tower.corrosion_duration_bonus
				stats_lbl.text += "\nCorrosion: %.1f DPS / %.1fs" % [corrosion_dps, corrosion_duration]
				var midas_cap := int(sim._cat_tier_value(selected_tower, "midas_cap")) + selected_tower.midas_cap_bonus
				if midas_cap > 0:
					var midas_ratio := sim._cat_tier_value(selected_tower, "midas_ratio") + selected_tower.midas_ratio_bonus
					stats_lbl.text += " | Midas: %d%% (%d/%d)" % [int(round(midas_ratio * 100.0)), selected_tower.midas_kibble_this_round, midas_cap]
		
		var next_xp = SimFeats.THRESHOLD_I
		if selected_tower.feat_rank == 1:
			next_xp = SimFeats.THRESHOLD_II
		elif selected_tower.feat_rank >= 2:
			next_xp = SimFeats.THRESHOLD_III
		feat_status_lbl.text = "Feat Rank: %d (XP: %d / %d)" % [selected_tower.feat_rank, int(selected_tower.feat_xp), next_xp]
		
		target_priority_btn.text = "Target: %s" % SimConstants.target_priority_to_string(selected_tower.target_priority)
		var has_brew := selected_tower.cat_id == "bub" and int(selected_tower.tiers.get("path_b", 0)) >= 3
		brew_target_btn.visible = has_brew
		if has_brew:
			var brew_target := sim._get_tower_by_id(selected_tower.brew_target_id)
			if brew_selecting_source == selected_tower:
				brew_target_btn.text = "Choose a cat on the map (Esc cancels)"
			else:
				brew_target_btn.text = "Reassign Brew: %s" % brew_target.cat_name if brew_target != null else "Select Brew Target"
			brew_target_btn.disabled = sim.round_in_progress
		
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
			h.get_effective_damage(), h.pierce, int(h.get_effective_range()), h.get_effective_cooldown()
		]
		var next_xp = SimHero.XP_TABLE[mini(h.level, SimHero.XP_TABLE.size() - 1)]
		feat_status_lbl.text = "Hero Match XP: %d / %d" % [int(h.xp), next_xp]
		target_priority_btn.text = "Hero Auto-Target: First"
		
		path_a_btn.visible = false
		path_b_btn.visible = false
		path_c_btn.visible = false
		brew_target_btn.visible = false
		
		var ability_1: Dictionary = h.hero_data.get("active_abilities", {}).get("ability_1", {})
		ability1_btn.text = "%s (Lvl 3)" % ability_1.get("name", "Ability 1") if h.level >= 3 else "Locked until Lvl 3"
		ability1_btn.disabled = not h.can_use_ability(1)
		if h.ability_1_cooldown_left > 0.0:
			ability1_btn.text += " (%.1fs)" % h.ability_1_cooldown_left
			
		var ability_2: Dictionary = h.hero_data.get("active_abilities", {}).get("ability_2", {})
		ability2_btn.text = "%s (Lvl 10)" % ability_2.get("name", "Ability 2") if h.level >= 10 else "Locked until Lvl 10"
		ability2_btn.disabled = not h.can_use_ability(2)
		if h.ability_2_cooldown_left > 0.0:
			ability2_btn.text += " (%.1fs)" % h.ability_2_cooldown_left
	else:
		path_a_btn.visible = true
		path_b_btn.visible = true
		path_c_btn.visible = true
		brew_target_btn.visible = false

func _get_mastery_text(_cat_id: String) -> String:
	return "Mastery Rank 1 (Next: Rank 2 at 400 XP -> Unlocks Tier 3)"

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
	var discounts = sim.get_tower_discounts(selected_tower)
	var price = sim.economy.calculate_price(base_cost, discounts)
	
	var pips := "●".repeat(cur_tier) + "○".repeat(5 - cur_tier)
	var stat_diff = _calculate_upgrade_stat_diff(selected_tower, path_key, next_tier_data)
	var disc_note = " (Discounted)" if not discounts.is_empty() else ""
	btn.text = "%s  %s\n%s: %s\n%d Kibble%s" % [path_name, pips, tier_name, stat_diff, price, disc_note]
	
	var check = sim.can_upgrade_tower(selected_tower, path_key)
	if not check.get("allowed", false):
		btn.disabled = true
		var r = str(check.get("reason", ""))
		if r == "MAX_TIER":
			btn.text += "\n[MAX TIER (5/5)]"
		elif r == "TWO_PATHS_CHOSEN":
			btn.text += "\n[LOCKED: 2 paths already chosen]"
		elif r.begins_with("LOCKED_BY_OTHER_TIER3"):
			var other_p = r.split(":")[1].replace("path_", "Path ").to_upper()
			btn.text += "\n[LOCKED: %s is Tier 3+, caps this at Tier 2]" % other_p
		elif r == "UNIQUE_T5_EXISTS":
			btn.text += "\n[LOCKED: Only 1 Tier-5 allowed on map]"
		elif r == "NO_KIBBLE":
			btn.text += "\n[NEED %d KIBBLE]" % price
	else:
		btn.disabled = false
		if cur_tier == 2:
			btn.text += "\n⚠️ Tier 3 caps secondary path at Tier 2!"

func _calculate_upgrade_stat_diff(tower: SimTower, _path_key: String, next_tier_data: Dictionary) -> String:
	var chunks: Array[String] = []
	if next_tier_data.has("damage"):
		var nd = int(next_tier_data["damage"])
		if nd != tower.damage:
			chunks.append("Dmg %d->%d" % [tower.damage, nd])
	if next_tier_data.has("pierce"):
		var np = int(next_tier_data["pierce"])
		if np != tower.pierce:
			chunks.append("Pierce %d->%d" % [tower.pierce, np])
	elif next_tier_data.has("bonus_pierce"):
		chunks.append("+%d Pierce" % int(next_tier_data["bonus_pierce"]))
	if next_tier_data.has("range"):
		var nr = int(next_tier_data["range"])
		if nr != int(tower.range_radius):
			chunks.append("Rng %d->%d" % [int(tower.range_radius), nr])
	if next_tier_data.has("cooldown"):
		var ncd = float(next_tier_data["cooldown"])
		if absf(ncd - tower.cooldown) > 0.01:
			chunks.append("CD %.2fs->%.2fs" % [tower.cooldown, ncd])
	if next_tier_data.has("see_shadow") and next_tier_data["see_shadow"] and not tower.see_shadow:
		chunks.append("✦ Night Eye")
	if next_tier_data.has("damage_type"):
		var dt = str(next_tier_data["damage_type"])
		if dt == "Bite":
			chunks.append("⚙️ Pops Iron")
		elif dt == "Blast":
			chunks.append("💥 Blast")
		elif dt == "Void":
			chunks.append("🌌 Void (Hits Ink)")
	if next_tier_data.has("freeze_duration"):
		chunks.append("❄️ Freeze %.1fs" % float(next_tier_data["freeze_duration"]))
	if next_tier_data.has("aura_radius"):
		chunks.append("Aura %d" % int(next_tier_data["aura_radius"]))
	if next_tier_data.has("active_ability"):
		chunks.append("🔔 Unlocks Active")
	return ", ".join(chunks) if not chunks.is_empty() else "New Technique"

func _crosspath_reason(path_key: String) -> String:
	for other in ["path_a", "path_b", "path_c"]:
		if other != path_key and selected_tower.tiers.get(other, 0) >= 3:
			return "%s is Tier 3, so this path stops at Tier 2" % other.capitalize()
	return "Two paths are already chosen"

func _upgrade_selected(path_key: String) -> void:
	if selected_tower != null:
		if sim.upgrade_tower(selected_tower, path_key):
			combat_vfx.note({"type": "upgrade", "x": selected_tower.position.x, "y": selected_tower.position.y})
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
		combat_vfx.note({"type": "ability", "x": pending_feat_tower.position.x, "y": pending_feat_tower.position.y})
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
		if match_paused:
			_toggle_pause()
			return
		if sim.start_next_round():
			brew_selecting_source = null
		_update_ui()

func _update_ui() -> void:
	if sim == null:
		return
	_update_profile_badge()
	lives_label.text = "%s: %d" % [_t("ui.lives", "Lives"), sim.lives]
	kibble_label.text = "%s: %s" % [_t("ui.kibble", "Kibble"), "Unlimited" if sim.economy.unlimited_kibble else str(sim.economy.kibble)]
	if testing_lab != null and lab_dps_label != null:
		var sample := testing_lab.get_dps_sample()
		lab_dps_label.text = "DPS: unavailable (0 ticks)" if int(sample.elapsed_ticks) <= 0 else "DPS: %.1f | HP: %d | Ticks: %d" % [float(sample.dps), int(sample.hp_removed), int(sample.elapsed_ticks)]
	var crawl_prefix := "D%d/%d · " % [alley_crawl.current_stage + 1, alley_crawl.stage_count] if alley_crawl_session != null else ""
	round_label.text = "%s%s %d/%d" % [crawl_prefix, _t("ui.round", "Round"), sim.current_round, sim.max_rounds]
	if map_select_btn != null:
		map_select_btn.disabled = sim.round_in_progress or alley_crawl_session != null
	if mode_select_btn != null:
		mode_select_btn.disabled = sim.round_in_progress or alley_crawl_session != null
	_update_wave_strip()
	_update_hero_commander_panel()
	if not sim.round_in_progress and not match_paused:
		if auto_start_timer > 0.0:
			start_round_btn.text = "%.1fs [Space]" % maxf(0.0, auto_start_timer)
		else:
			start_round_btn.text = "▶ %s [Space]" % _t("ui.start", "Start")
	start_round_btn.disabled = sim.round_in_progress or sim.match_won or sim.match_lost or feat_modal.visible
	if selected_tower != null or selected_is_hero:
		_update_inspector()
	if (sim.match_won or sim.match_lost) and results_modal != null and not results_modal.visible:
		_show_results_dialog(sim.match_won)

func _update_wave_strip() -> void:
	var next_round := sim.current_round if sim.round_in_progress else sim.current_round + 1
	var groups: Array = sim.round_data.get("rounds", {}).get(str(next_round), [])
	if groups.is_empty():
		incoming_info.text = _t("ui.trail_clear", "Trail clear") if sim.match_won else _t("ui.no_wave", "No wave authored yet")
		return
	var chunks: Array[String] = []
	var threats: Array[String] = []
	var has_shadow := false
	var has_plated := false
	var routes := {}
	
	for group in groups:
		var kind := str(group.get("rat", group.get("coat", "mouse"))).capitalize()
		var count := int(group.get("count", 1))
		var tags: Array[String] = []
		if group.get("shadow", false) or group.get("is_shadow", false):
			has_shadow = true
			tags.append("✦Shadow")
		if group.get("plated", false) or group.get("is_plated", false):
			has_plated = true
			tags.append("🛡️Plated")
		var r_idx = group.get("route", 0)
		routes[r_idx] = true
		
		var tag_str = (" " + "/".join(tags)) if not tags.is_empty() else ""
		chunks.append("%s x%d%s" % [kind, count, tag_str])
		
		var coat_key = str(group.get("coat", "")).to_lower()
		var rat_key = str(group.get("rat", "")).to_lower()
		
		if coat_key == "iron" and not threats.has("⚠️ Iron: Claw immune (Use Bite/Blast/Magic)"):
			threats.append("⚠️ Iron: Claw immune (Use Bite/Blast/Magic)")
		elif coat_key == "soot" and not threats.has("⚠️ Soot: Blast immune (Use Claw/Bite/Magic)"):
			threats.append("⚠️ Soot: Blast immune (Use Claw/Bite/Magic)")
		elif coat_key == "ink" and not threats.has("⚠️ Ink: Magic immune (Use Claw/Blast/Bite)"):
			threats.append("⚠️ Ink: Magic immune (Use Claw/Blast/Bite)")
		elif coat_key == "frost" and not threats.has("⚠️ Frost: Freeze & Chill immune"):
			threats.append("⚠️ Frost: Freeze & Chill immune")
		elif coat_key == "porcelain" and not threats.has("⚠️ Porcelain: Multi-layer high-speed shell"):
			threats.append("⚠️ Porcelain: Multi-layer high-speed shell")
		
		if rat_key == "matriarch" and not threats.has("👑 RAT MATRIARCH: Immune to all stuns/slows/freezes!"):
			threats.append("👑 RAT MATRIARCH: Immune to all stuns/slows/freezes!")
		elif rat_key != "" and not threats.has("🐀 Heavy Rat: High HP boss"):
			threats.append("🐀 %s: Heavy boss with child swarm!" % rat_key.capitalize())
			
	if has_shadow and not threats.has("✦ Shadow: Invisible without Night Eye"):
		threats.append("✦ Shadow units: Invisible without Night Eye")
	if has_plated and not threats.has("🛡️ Plated: Armor absorbs initial damage"):
		threats.append("🛡️ Plated units: Armor absorbs initial damage")
		
	var route_str := ""
	if routes.size() > 1:
		route_str = "\nActive Routes: Split across %d paths!" % routes.size()
	elif routes.has(1):
		route_str = "\nRoute: Alternate Path B"
		
	var threat_str := ""
	if not threats.is_empty():
		threat_str = "\n" + "\n".join(threats)
		
	incoming_info.text = ("Next Wave (R%d):\n" % next_round) + "\n".join(chunks) + route_str + threat_str

# ==================== DRAWING & VISUALIZATION ====================

func _draw() -> void:
	if sim == null or actor_drawer == null:
		return
	if world_drawer != null:
		world_drawer.draw_world(self, grass_tex, cobble_tex, prop_sprites, sim)
	if testing_lab != null:
		_draw_lab_overlays()
	var displayed_s: Dictionary = {}
	for unit in sim.units:
		displayed_s[unit.id] = lerpf(float(previous_unit_s.get(unit.id, unit.s)), unit.s, interpolation_alpha)
	actor_drawer.draw_actors(self, sim, displayed_s, selected_tower, selected_is_hero, cat_sprites, mouse_sprites, rat_sprites)
	_draw_brew_targets()
	if combat_vfx != null:
		combat_vfx.draw(self)
	_draw_placement_preview()

func _draw_lab_overlays() -> void:
	var colors := {
		"land": Color(0.25, 0.85, 0.30, 0.14),
		"water": Color(0.20, 0.65, 1.00, 0.25),
		"perches": Color(1.00, 0.75, 0.20, 0.28)
	}
	for entry in [
		{"enabled": lab_overlay_land, "key": "land"},
		{"enabled": lab_overlay_water, "key": "water"},
		{"enabled": lab_overlay_perch, "key": "perches"}
	]:
		if not bool(entry.enabled):
			continue
		for zone in sim.placement_zones.get(entry.key, []):
			if not (zone is Dictionary):
				continue
			var color: Color = colors[entry.key]
			if zone.has("radius"):
				draw_circle(Vector2(float(zone.get("x", 0.0)), float(zone.get("y", 0.0))), float(zone.get("radius", 0.0)), color)
			else:
				draw_rect(Rect2(float(zone.get("x", 0.0)), float(zone.get("y", 0.0)), float(zone.get("width", 0.0)), float(zone.get("height", 0.0))), color, true)
	if lab_overlay_blocker:
		for blocker in sim.sight_blockers:
			draw_rect(blocker, Color(0.95, 0.20, 0.20, 0.35), true)
		for obstacle in sim.get_removable_obstacles():
			var base: Dictionary = obstacle.get("base", {})
			draw_rect(Rect2(float(base.get("x", 0.0)), float(base.get("y", 0.0)), float(base.get("width", 0.0)), float(base.get("height", 0.0))), Color(0.95, 0.20, 0.20, 0.35), true)
	if lab_overlay_path:
		var ribbon_width := float(sim.map_data.get("path_width", 40.0))
		for path_info in sim.paths:
			var points := PackedVector2Array()
			for point in path_info.get("points", []):
				points.append(point)
			if points.size() >= 2:
				draw_polyline(points, Color(0.95, 0.25, 0.80, 0.42), ribbon_width, true)

func _draw_brew_targets() -> void:
	if brew_selecting_source == null:
		return
	draw_arc(brew_selecting_source.position, brew_selecting_source.get_effective_range(), 0, TAU, 48, Color("88e09a"), 2.0)
	for candidate in sim.towers:
		if candidate == brew_selecting_source:
			continue
		var allowed := bool(sim.can_assign_brew(brew_selecting_source, candidate).get("allowed", false))
		draw_arc(candidate.position, candidate.footprint_radius + 8.0, 0, TAU, 24, Color("79e68f") if allowed else Color("9b5555"), 2.5)

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
		var is_hovered = (not is_sel) and (placing_cat_id == "") and (mouse_pos.distance_to(t.position) <= t.footprint_radius + 15.0)
		var base_col = CAT_COLORS.get(t.cat_id, Color(0.8, 0.5, 0.2))
		
		# Range indicator if selected or hovered
		if is_sel:
			draw_circle(t.position, t.range_radius, Color(base_col.r, base_col.g, base_col.b, 0.15))
			draw_arc(t.position, t.range_radius, 0, TAU, 48, Color(1.0, 0.85, 0.2, 0.8), 2.0)
			draw_arc(t.position, t.footprint_radius + 4.0, 0, TAU, 32, Color(1.0, 0.9, 0.3, 0.9), 2.5)
		elif is_hovered:
			draw_circle(t.position, t.range_radius, Color(base_col.r, base_col.g, base_col.b, 0.08))
			draw_arc(t.position, t.range_radius, 0, TAU, 40, Color(1.0, 1.0, 1.0, 0.4), 1.5)
			
		_draw_cat_sprite(t.position, t.cat_id, t.footprint_radius, base_col, t.feat_rank)
		
	# Draw Hero if placed
	if sim.hero != null:
		var is_sel = selected_is_hero
		var h_pos = sim.hero.position
		var is_hovered = (not is_sel) and (placing_cat_id == "") and (mouse_pos.distance_to(h_pos) <= 35.0)
		if is_sel:
			draw_circle(h_pos, sim.hero.current_range, Color(0.4, 0.6, 1.0, 0.15))
			draw_arc(h_pos, sim.hero.current_range, 0, TAU, 48, Color(0.4, 0.8, 1.0, 0.8), 2.0)
			draw_arc(h_pos, 24.0, 0, TAU, 32, Color(1.0, 0.85, 0.2, 0.9), 2.5)
		elif is_hovered:
			draw_circle(h_pos, sim.hero.current_range, Color(0.4, 0.6, 1.0, 0.08))
			draw_arc(h_pos, sim.hero.current_range, 0, TAU, 40, Color(0.6, 0.9, 1.0, 0.4), 1.5)
		_draw_hero_sprite(h_pos, sim.hero)

func _blit(tex: Texture2D, pos: Vector2, height: float, alpha: float, foot_anchor: float) -> void:
	if tex == null:
		return
	var is_sheet := tex.get_width() > tex.get_height() and tex.get_height() >= 32
	if is_sheet:
		var cell_h := float(tex.get_height())
		var dest := Rect2(pos - Vector2(height * 0.5, height * foot_anchor), Vector2(height, height))
		var src := Rect2(Vector2(0, 0), Vector2(cell_h, cell_h))
		draw_texture_rect_region(tex, dest, src, Color(1, 1, 1, alpha))
	else:
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
	var tex = cat_sprites.get(h.id)
	if tex != null:
		_draw_cat_sprite(pos, h.id, 22.0, Color(0.40, 0.45, 0.52), 0)
	else:
		draw_circle(pos, 22.0, Color(0.40, 0.45, 0.52))
		draw_arc(pos, 22.0, 0, TAU, 28, Color("ffd763"), 2.0)
		var initial: String = h.id.substr(0, 1).to_upper()
		draw_string(ThemeDB.fallback_font, pos + Vector2(-6.0, 5.0), initial, HORIZONTAL_ALIGNMENT_CENTER, 12, 14, Color.WHITE)
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
	var chk: Dictionary = {}
	
	if is_placing_hero:
		chk = sim.can_place_hero_at(placing_cat_id, mouse_pos)
		valid = chk.get("valid", false)
		range_r = 160.0
		cost = chk.get("price", 600)
	else:
		chk = sim.can_place_tower_at(placing_cat_id, mouse_pos)
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
		var icons := {"road": "⛔ road", "surface": "💧 surface", "cat": "🐾 cat", "hero": "🐾 hero", "permanent_obstacle": "🏠 fixed", "removable_obstacle": "🧺 clearable", "kibble": "🍖 Kibble"}
		tip += " — %s" % icons.get(str(chk.get("code", "")), str(chk.get("reason", "invalid")))
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
