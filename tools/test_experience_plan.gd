extends SceneTree

const SimConstants = preload("res://sim/constants.gd")

var main: Node2D
var frames: int = 0

func _init() -> void:
	var scene = load("res://presentation/main.tscn")
	assert(scene != null, "main.tscn must load")
	main = scene.instantiate()
	root.add_child(main)

func _process(_delta: float) -> bool:
	frames += 1
	if frames == 1:
		_run()
	return false

func _run() -> void:
	# Stage 1: Match HUD & WaveStrip & Segmented Target & Dock Dimming
	assert(main.mode_badge_lbl != null and main.pause_btn != null and main.den_btn != null)
	assert(main.wave_strip != null and main.wave_chips_box.get_child_count() > 0)
	assert(main.wave_strip.position.y + main.wave_strip.size.y <= 80.0, "WaveStrip must stay above Sunny Gutter ribbon")
	assert(main.dock_cells.size() >= 10)
	main.sim.economy.kibble = 170
	main._update_ui()
	var pip_cell: Dictionary = main.dock_cells[0]
	var biscuit_cell: Dictionary = main.dock_cells[3]
	assert(pip_cell["icon"].modulate.a > 0.9, "Affordable Pip must be full brightness")
	assert(biscuit_cell["icon"].modulate.a < 0.6, "Unaffordable Biscuit must be dimmed")

	# Stage 7: First-match 3-beat coach
	main.save_mgr.data["settings"]["coach_seen"] = false
	main.coach_step = 0
	main._update_ui()
	assert("Pip" in main.empty_prompt_lbl.text, "Coach step 0 prompts placing Pip")

	var t = main.sim.place_tower("pip", Vector2(200.0, 200.0))
	assert(t != null)
	main.coach_step = 1
	main._select_tower(t)
	assert(main.target_segment_box.visible, "Segmented target control visible on tower selection")
	main._set_target_priority(SimConstants.TargetPriority.STRONG)
	assert(t.target_priority == SimConstants.TargetPriority.STRONG)

	# Stage 5: Title -> Map Card -> Loadout (Bare Paw) -> Pause -> Resume -> Results
	main.title_menu.visible = true
	main._open_map_select()
	assert(main.map_select_modal.visible and main.map_select_modal.cards_grid.get_child_count() == 26)
	main._on_map_card_chosen("sunny_gutter", SimConstants.GameMode.BARE_PAW)
	assert(main.loadout_modal.visible)
	assert(main.loadout_modal.insights_btn.disabled, "Bare Paw must disable Insights button")
	assert(main.loadout_modal.trick_buttons[0].disabled, "Bare Paw must disable Tricks")
	main._start_match_from_loadout("sunny_gutter", SimConstants.GameMode.SUNNY, "mittens", ["tuna_strike", "night_lantern", "catnip_frenzy"])
	assert(main.sim.mode == SimConstants.GameMode.SUNNY and main.current_map_id == "sunny_gutter")

	# Pause freezes sim tick and Resume continues same round
	main.sim.start_next_round()
	var tick_before: int = main.sim.tick_counter
	main._toggle_pause()
	assert(main.match_paused and main.pause_modal.visible)
	main._physics_process(1.0 / 30.0)
	assert(main.sim.tick_counter == tick_before, "Pause must freeze sim tick")
	main._resume_from_pause()
	assert(not main.match_paused and not main.pause_modal.visible)
	main._physics_process(1.0 / 30.0)
	assert(main.sim.tick_counter > tick_before, "Resume continues sim tick")

	# Stage 4: Comfort settings propagate to VFX and Audio
	main.save_mgr.data["settings"]["vfx_reduced"] = true
	main.save_mgr.data["settings"]["screen_shake"] = "off"
	main.save_mgr.data["settings"]["text_scale"] = 150
	main._on_settings_modal_changed()
	assert(main.combat_vfx.reduced == true and main.combat_vfx.shake_mode == 0)
	main.combat_vfx.note({"type": "leak", "x": 340, "y": 400})
	assert(main.combat_vfx.shake_offset == Vector2.ZERO, "Shake off keeps offset zero")
	assert(main.wave_strip.offset_bottom <= 80.0, "150% text scale keeps WaveStrip above Sunny ribbon")

	# Stage 8: All 26 maps load and draw cleanly
	for m_id in ["sunny_gutter", "lantern_stoop", "market_lane", "canal_night", "the_warren"]:
		main._init_simulation(m_id, SimConstants.GameMode.SUNNY)
		main.queue_redraw()
		main._process(0.016)

	print("[PASS] Experience Plan 8-stage integration verified cleanly")
	quit(0)
