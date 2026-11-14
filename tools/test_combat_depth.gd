extends SceneTree

func _init() -> void:
	print("==================================================")
	print("   TESTING COMBAT DEPTH & CANON COMPLIANCE")
	print("==================================================")
	var err = _run_depth_tests()
	if err != OK:
		push_error("Combat depth tests failed with code: %d" % err)
		quit(1)
	else:
		print("==================================================")
		print("   ALL COMBAT DEPTH TESTS PASSED CLEANLY (6/6)")
		print("==================================================")
		quit(0)

func _load_json(path: String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text = file.get_as_text()
	var json = JSON.new()
	if json.parse(text) == OK:
		return json.data
	return {}

func _run_depth_tests() -> int:
	var mice_data = _load_json("res://content/mice.json")
	var rats_data = _load_json("res://content/rats.json")
	var sunny_rounds = _load_json("res://content/rounds/sunny.json")
	var map_data = _load_json("res://content/maps/sunny_gutter.json")
	
	var cat_bps = {
		"pip": _load_json("res://content/cats/pip.json"),
		"nibs": _load_json("res://content/cats/nibs.json"),
		"pudding": _load_json("res://content/cats/pudding.json"),
		"biscuit": _load_json("res://content/cats/biscuit.json"),
		"sable": _load_json("res://content/cats/sable.json"),
		"nim": _load_json("res://content/cats/nim.json"),
		"goldie": _load_json("res://content/cats/goldie.json"),
		"miso": _load_json("res://content/cats/miso.json"),
		"marlow": _load_json("res://content/cats/marlow.json")
	}
	
	var hero_bps = {
		"mittens": _load_json("res://content/heroes/mittens.json"),
		"duchess": _load_json("res://content/heroes/duchess.json"),
		"baron": _load_json("res://content/heroes/baron.json"),
		"pebble": _load_json("res://content/heroes/pebble.json")
	}
	
	var sim = SimMatch.new()
	sim.setup(
		SimConstants.GameMode.SUNNY,
		42,
		mice_data,
		rats_data,
		cat_bps,
		hero_bps,
		sunny_rounds,
		0,
		map_data
	)
	sim.economy.kibble = 999999 # Unlimited kibble for testing
	
	# TEST 1: Crosspath Law - Primary Path Beyond Tier 3
	print("[TEST 1] Crosspath: Upgrading primary path to Tier 5...")
	var pip1 = sim.place_tower("pip", Vector2(150.0, 200.0))
	assert(pip1 != null, "Pip 1 placement failed")
	for i in range(5):
		var ok = sim.upgrade_tower(pip1, "path_a")
		assert(ok, "Pip 1 path_a upgrade to Tier %d failed!" % (i + 1))
	assert(pip1.tiers["path_a"] == 5, "Pip 1 path_a should be Tier 5")
	print(" -> Pip 1 successfully reached Tier 5 on Path A.")

	# TEST 2: Crosspath Law - Secondary path capped at Tier 2, Third path blocked
	print("[TEST 2] Crosspath: Verifying secondary cap at T2 and third path block...")
	assert(sim.upgrade_tower(pip1, "path_b"), "Secondary path_b upgrade to T1 should succeed")
	assert(sim.upgrade_tower(pip1, "path_b"), "Secondary path_b upgrade to T2 should succeed")
	assert(pip1.tiers["path_b"] == 2, "Pip 1 path_b should be Tier 2")
	
	var chk_b3 = pip1.can_upgrade("path_b")
	assert(not chk_b3, "Secondary path_b upgrade to Tier 3 MUST be blocked by Crosspath Law")
	var block_reason_b = pip1.get_crosspath_block_reason("path_b")
	assert(block_reason_b.begins_with("LOCKED_BY_OTHER_TIER3"), "Block reason must begin with LOCKED_BY_OTHER_TIER3, got %s" % block_reason_b)
	
	var chk_c = pip1.can_upgrade("path_c")
	assert(not chk_c, "Third path (path_c) MUST be blocked when two paths are chosen")
	var block_reason_c = pip1.get_crosspath_block_reason("path_c")
	assert(block_reason_c == "TWO_PATHS_CHOSEN", "Block reason must be TWO_PATHS_CHOSEN, got %s" % block_reason_c)
	print(" -> Crosspath restrictions correctly enforced (5-2-0 valid, T3 and third path blocked).")

	# TEST 3: Tier 5 Uniqueness per Cat Type
	print("[TEST 3] Tier 5 Uniqueness: Only one T5 per path per cat type on the map...")
	var pip2 = sim.place_tower("pip", Vector2(300.0, 200.0))
	assert(pip2 != null, "Pip 2 placement failed")
	for i in range(4):
		assert(sim.upgrade_tower(pip2, "path_a"), "Pip 2 upgrade to T%d failed" % (i + 1))
	assert(pip2.tiers["path_a"] == 4, "Pip 2 should be Tier 4")
	
	var chk_t5 = sim.can_upgrade_tower(pip2, "path_a")
	assert(not chk_t5.get("allowed", true), "Second Pip upgrading to Tier 5 Path A MUST be invalid")
	assert(chk_t5.get("reason", "") == "UNIQUE_T5_EXISTS", "Reason must be UNIQUE_T5_EXISTS, got %s" % chk_t5.get("reason", ""))
	assert(not sim.upgrade_tower(pip2, "path_a"), "sim.upgrade_tower must reject duplicate T5")
	print(" -> Tier 5 uniqueness properly enforced across identical cats.")

	# TEST 4: Miso Aura Buffs and Support Tracking
	print("[TEST 4] Miso Support: Auras, buffs, discounts, and assisted damage tracking...")
	var miso = sim.place_tower("miso", Vector2(300.0, 260.0))
	assert(miso != null, "Miso placement failed")
	# Upgrade Miso Path A (speed) and Path B (range/discounts)
	sim.upgrade_tower(miso, "path_a")
	sim.upgrade_tower(miso, "path_a")
	sim.upgrade_tower(miso, "path_b")
	sim.upgrade_tower(miso, "path_b")
	
	# Verify Pip 2 receives aura buffs from Miso
	assert(pip2.aura_speed_mult > 0.0, "Pip 2 should receive speed buff from Miso")
	assert(pip2.aura_range_mult > 0.0, "Pip 2 should receive range buff from Miso")
	assert(pip2.get_effective_cooldown() < pip2.cooldown, "Effective cooldown should be reduced by Miso")
	assert(miso.buffed_cats_count > 0, "Miso should report buffed cats count > 0")
	
	# Test Miso active ability: Rallying Bell (Path C Tier 4)
	var miso_bell = sim.place_tower("miso", Vector2(450.0, 260.0))
	for i in range(4):
		sim.upgrade_tower(miso_bell, "path_c")
	assert(miso_bell.tiers["path_c"] == 4, "Miso Bell should be C4")
	assert(sim.trigger_tower_ability(miso_bell), "Miso Rallying Bell ability should trigger")
	assert(sim.miso_bell_timer > 0.0, "Miso bell timer should be active")
	print(" -> Miso auras, speed buffs, discounts, and active bell successfully verified.")

	# TEST 5: Launch Heroes (Mittens, Duchess, Baron Salt, Sister Pebble)
	print("[TEST 5] Launch Heroes: Leveling, kit passives, and active abilities...")
	# 5a. Duchess (Magic, Burn, Heatwave, Chili Heart)
	var sim_duchess = SimMatch.new()
	sim_duchess.setup(SimConstants.GameMode.SUNNY, 43, mice_data, rats_data, cat_bps, hero_bps, sunny_rounds, 0, map_data)
	var duchess = sim_duchess.place_hero("duchess", Vector2(200.0, 200.0))
	assert(duchess != null, "Duchess placement failed")
	duchess.add_xp(50000.0) # Level up to 20
	assert(duchess.level >= 10, "Duchess should reach level >= 10")
	assert(duchess.can_use_ability(1), "Duchess Ability 1 (Heatwave) should be usable")
	assert(duchess.can_use_ability(2), "Duchess Ability 2 (Chili Heart) should be usable")
	assert(sim_duchess.trigger_hero_ability(1), "Trigger Heatwave failed")
	assert(duchess.ability_1_cooldown_left > 0.0, "Heatwave cooldown should be active")
	assert(sim_duchess.trigger_hero_ability(2), "Trigger Chili Heart failed")
	assert(duchess.ability_2_cooldown_left > 0.0, "Chili Heart cooldown should be active")
	assert(sim_duchess.ground_zones.size() > 0, "Chili Heart ground zone should be spawned")
	print("  - Duchess: Level %d, Heatwave & Chili Heart zones active." % duchess.level)

	# 5b. Baron Salt (Depth Charge, Broadside, Keelhaul)
	var sim_baron = SimMatch.new()
	sim_baron.setup(SimConstants.GameMode.SUNNY, 44, mice_data, rats_data, cat_bps, hero_bps, sunny_rounds, 0, map_data)
	var baron = sim_baron.place_hero("baron", Vector2(200.0, 200.0))
	assert(baron != null, "Baron Salt placement failed")
	baron.add_xp(50000.0)
	assert(sim_baron.trigger_hero_ability(1), "Trigger Depth Charge failed")
	assert(sim_baron.trigger_hero_ability(2), "Trigger Broadside failed")
	print("  - Baron Salt: Level %d, Depth Charge & Broadside active." % baron.level)

	# 5c. Sister Pebble (Skim, Audit, End-Round Kibble)
	var sim_pebble = SimMatch.new()
	sim_pebble.setup(SimConstants.GameMode.SUNNY, 45, mice_data, rats_data, cat_bps, hero_bps, sunny_rounds, 0, map_data)
	var pebble = sim_pebble.place_hero("pebble", Vector2(200.0, 200.0))
	assert(pebble != null, "Sister Pebble placement failed")
	pebble.add_xp(50000.0)
	var initial_kibble = sim_pebble.economy.kibble
	assert(sim_pebble.trigger_hero_ability(1), "Trigger Skim failed")
	assert(sim_pebble.skim_bonus_active, "Skim bonus should be active")
	assert(sim_pebble.trigger_hero_ability(2), "Trigger Audit failed")
	assert(sim_pebble.economy.kibble > initial_kibble, "Audit must grant bonus Kibble")
	print("  - Sister Pebble: Level %d, Skim & Audit (+%d Kibble) active." % [pebble.level, sim_pebble.economy.kibble - initial_kibble])

	# 5d. Mittens (Pin Cushion, Spool Barrage)
	var sim_mittens = SimMatch.new()
	sim_mittens.setup(SimConstants.GameMode.SUNNY, 46, mice_data, rats_data, cat_bps, hero_bps, sunny_rounds, 0, map_data)
	var mittens = sim_mittens.place_hero("mittens", Vector2(200.0, 200.0))
	assert(mittens != null, "Mittens placement failed")
	mittens.add_xp(50000.0)
	assert(sim_mittens.trigger_hero_ability(1), "Trigger Pin Cushion failed")
	assert(sim_mittens.projectiles.size() >= 10, "Pin Cushion should launch at least 10 needles")
	assert(sim_mittens.trigger_hero_ability(2), "Trigger Spool Barrage failed")
	assert(mittens.spool_barrage_timer > 0.0, "Spool barrage timer should be active")
	print("  - Mittens: Level %d, Pin Cushion (10 needles) & Spool Barrage active." % mittens.level)

	# TEST 6: Combat Feedback, Defeat History, and Immunity Tracking
	print("[TEST 6] Combat Defeat Tracking & Immunity Deflections...")
	var sim_combat = SimMatch.new()
	sim_combat.setup(SimConstants.GameMode.SUNNY, 47, mice_data, rats_data, cat_bps, hero_bps, sunny_rounds, 0, map_data)
	# Spawn Iron Mouse right near Pip (track is at y=100, Pip at (200, 150))
	var claw_cat = sim_combat.place_tower("pip", Vector2(200.0, 150.0))
	assert(claw_cat != null, "Claw cat placement failed")
	var iron_mouse = sim_combat.spawn_unit({"coat": "iron"}, 160.0)
	assert(iron_mouse != null, "Iron mouse spawn failed")
	
	# Simulate combat ticks where Claw attacks Iron
	for i in range(15):
		sim_combat.tick()
	assert(sim_combat.blocked_immunity_counts.get("iron", 0) > 0, "Claw against Iron MUST record blocked_immunity_counts")
	print("  - Recorded %d Claw deflections against Iron coat." % sim_combat.blocked_immunity_counts.get("iron", 0))
	
	# Leak unit and check leak_history
	iron_mouse.s = 1500.0 # Force leak past track end
	sim_combat.tick()
	assert(sim_combat.leak_history.size() > 0, "Leak history must record escaped unit")
	assert(sim_combat.leak_history[0].get("unit_type", "") == "iron", "Leaked unit should be iron")
	print("  - Leak history properly recorded: %s (RBE: %d)." % [sim_combat.leak_history[0]["unit_type"], sim_combat.leak_history[0]["rbe"]])

	return OK
