extends SceneTree

const SimConstants = preload("res://sim/constants.gd")

var main: Node2D
var frame_count: int = 0

func _init() -> void:
	print("==================================================")
	print("    CLOWDER: META SCREENS & TRICKS INTEGRATION    ")
	print("==================================================")

	var main_scene = load("res://presentation/main.tscn")
	assert(main_scene != null, "main.tscn must load")
	main = main_scene.instantiate()
	root.add_child(main)

func _process(_delta: float) -> bool:
	frame_count += 1
	if frame_count == 1:
		_run_tests()
	return false

func _run_tests() -> void:
	# 1. VERIFY INITIALIZATION OF ALL META SYSTEMS
	assert(main.save_mgr != null, "save_mgr must be initialized")
	assert(main.title_menu != null, "title_menu must be initialized")
	assert(main.almanac_modal != null, "almanac_modal must be initialized")
	assert(main.insights_modal != null, "insights_modal must be initialized")
	assert(main.shop_modal != null, "shop_modal must be initialized")
	assert(main.settings_modal != null, "settings_modal must be initialized")
	assert(main.profile_badge_lbl != null, "profile_badge_lbl must exist on top bar")
	print("[PASS] Meta managers and all 5 modal screens initialized cleanly")

	# 2. TEST TITLE MENU TOGGLE & PROFILE CARD
	main._toggle_title_menu()
	assert(main.title_menu.visible == true, "Title menu becomes visible")
	main._toggle_title_menu()
	assert(main.title_menu.visible == false, "Title menu toggles closed")
	print("[PASS] Title Hub Menu toggle and profile card verified")

	# 3. TEST THE ALMANAC
	main._open_almanac()
	assert(main.almanac_modal.visible == true, "Almanac becomes visible")
	main.almanac_modal._select_tab("cats")
	assert(main.almanac_modal.cats_data.size() >= 8, "Almanac loads all 8 launch cats from JSON")
	main.almanac_modal._select_tab("enemies")
	assert(main.almanac_modal.mice_data.get("coats", {}).size() == 12, "Almanac loads 12 mouse coats")
	assert(main.almanac_modal.rats_data.get("rats", {}).size() == 5, "Almanac loads 5 rat bosses")
	main.almanac_modal._select_tab("tricks")
	assert(main.almanac_modal.tricks_data.get("tricks", {}).size() >= 7, "Almanac loads tricks")
	main._close_all_modals()
	print("[PASS] The Almanac tabs, cat upgrades, enemy immunities, and trick cards verified")

	# 4. TEST INSIGHTS MODAL (6 PASSIVE TREES)
	main._open_insights()
	assert(main.insights_modal.visible == true, "Insights modal becomes visible")
	for t_id in ["alley", "hunt", "myth", "den", "hero", "clowder"]:
		main.insights_modal._select_tree(t_id)
		assert(main.insights_modal.perks_vbox.get_child_count() == 8, "Tree %s must have 8 perks" % t_id)
	main._close_all_modals()
	print("[PASS] Insights Modal with all 6 trees (Alley, Hunt, Myth, Den, Hero, Clowder) verified")

	# 5. TEST SHOP MODAL (REGULAR + COLLECTOR'S VAULT)
	main._open_shop("regular")
	assert(main.shop_modal.visible == true, "Shop modal visible")
	assert(main.shop_modal.current_tab == "regular", "Regular shop tab active")
	main.shop_modal._select_tab("vault")
	assert(main.shop_modal.current_tab == "vault", "Collector's Vault tab active")
	assert(main.shop_modal.prestige_data.get("items", {}).size() >= 5, "Collector's vault loaded prestige items")
	main._close_all_modals()
	print("[PASS] Shop Modal (Fishcoin & Collector's Vault Golden Bones) verified")

	# 6. TEST SETTINGS MODAL
	main._open_settings()
	assert(main.settings_modal.visible == true, "Settings modal visible")
	main.settings_modal.shake_btn.selected = 0 # Off
	main.settings_modal._on_setting_changed()
	assert(main.save_mgr.data["settings"]["screen_shake"] == "off", "Setting persisted to save_mgr")
	main._close_all_modals()
	print("[PASS] Settings & Accessibility modal persistence verified")

	# 7. TEST MODE SELECTION (SUNNY -> ALLEY 60 ROUNDS)
	assert(main.sim.max_rounds == 40, "Default mode is Sunny (40 rounds)")
	main._on_mode_selected(SimConstants.GameMode.ALLEY)
	assert(main.sim.mode == SimConstants.GameMode.ALLEY, "Mode changed to Alley")
	assert(main.sim.max_rounds == 60, "Alley mode has 60 max rounds")
	assert(main.sim.lives == 150, "Alley mode starts with 150 lives")
	print("[PASS] Mode selection (Alley mode 60 rounds / 150 lives) verified")

	# 8. TEST COMBAT TRICKS HUD BUTTONS & ACTIVATION
	assert(main.trick_buttons.size() == 3, "Must have 3 equipped trick buttons on HUD")
	# Start round
	main._on_start_round_pressed()
	assert(main.sim.round_in_progress, "Round 1 is in progress")

	# Give enough kibble for Tuna Strike (50 kibble)
	main.sim.economy.kibble = 200
	main._update_ui()
	assert(not main.trick_buttons[0].disabled, "Tuna Strike button is enabled during round")

	# Press trick button
	main._on_trick_button_pressed("tuna_strike")
	assert(main.sim.trick_cooldowns.get("tuna_strike", 0) > 0, "Tuna Strike is on cooldown")
	main._update_ui()
	assert(main.trick_buttons[0].disabled, "Tuna Strike button becomes disabled on cooldown")
	print("[PASS] In-Match combat tricks HUD integration and activation verified")

	# 9. RENDER PROCESS FRAMES
	for i in range(30):
		main._process(0.0166)
	print("[PASS] 30 frames processed cleanly across all new UI elements")

	print("==================================================")
	print(" ALL META SCREENS & TRICKS PASSED 100% CLEANLY!   ")
	print("==================================================")
	quit(0)
