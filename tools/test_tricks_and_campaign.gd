extends SceneTree

const SimConstants = preload("res://sim/constants.gd")
const SimMatch = preload("res://sim/match.gd")
const SimTower = preload("res://sim/tower.gd")

func _init() -> void:
	print("==================================================")
	print("      CLOWDER: TRICKS & CAMPAIGN VERIFICATION     ")
	print("==================================================")

	# 1. VERIFY CAMPAIGN.JSON (100 ROUNDS)
	var camp_file = FileAccess.open("res://content/rounds/campaign.json", FileAccess.READ)
	assert(camp_file != null, "campaign.json must exist")
	var camp_data: Dictionary = JSON.parse_string(camp_file.get_as_text())
	camp_file.close()

	var rounds_dict: Dictionary = camp_data.get("rounds", {})
	assert(rounds_dict.size() == 100, "Campaign must have exactly 100 rounds")
	print("[PASS] campaign.json verified with 100 authored/filler rounds")

	# Check boss milestones
	assert(rounds_dict["60"][0].get("rat") == "bristle", "Round 60 must spawn Bristle")
	assert(rounds_dict["80"][0].get("rat") == "monarch", "Round 80 must spawn Monarch")
	assert(rounds_dict["90"][0].get("rat") == "dusk", "Round 90 must spawn Dusk")
	assert(rounds_dict["100"][0].get("rat") == "matriarch", "Round 100 must spawn Matriarch")
	print("[PASS] Boss milestone rounds (60, 80, 90, 100) verified")

	# 2. SETUP SIM MATCH FOR TESTING
	var mice_file = FileAccess.open("res://content/mice.json", FileAccess.READ)
	var mice_data = JSON.parse_string(mice_file.get_as_text())
	mice_file.close()

	var rats_file = FileAccess.open("res://content/rats.json", FileAccess.READ)
	var rats_data = JSON.parse_string(rats_file.get_as_text())
	rats_file.close()

	var tricks_file = FileAccess.open("res://content/tricks.json", FileAccess.READ)
	var tricks_data = JSON.parse_string(tricks_file.get_as_text())
	tricks_file.close()

	var pip_file = FileAccess.open("res://content/cats/pip.json", FileAccess.READ)
	var pip_data = JSON.parse_string(pip_file.get_as_text())
	pip_file.close()

	var sim = SimMatch.new()
	sim.setup(
		SimConstants.GameMode.ALLEY,
		1337,
		mice_data,
		rats_data,
		{"pip": pip_data},
		{},
		camp_data
	)
	sim.load_tricks_data(tricks_data)

	# 3. TEST SUPER PORCELAIN (ROUND 81+)
	sim.current_round = 85
	var super_u = sim.spawn_unit({"coat": "porcelain"}, 0.0)
	assert(super_u.is_super == true, "Must be flagged super porcelain at round 85")
	assert(super_u.layer_hp == 60, "Super Porcelain shell HP must be 60")
	print("[PASS] Super Porcelain mechanics at round 85 verified (Shell HP: 60)")

	# 4. TEST TUNA STRIKE TRICK & CEILING
	var target_pos = Vector2(100, 100)
	var mat_unit = sim.spawn_unit({"rat": "matriarch"}, 0.0)
	sim.economy.kibble = 500

	var tuna_res = sim.use_trick("tuna_strike", target_pos)
	assert(tuna_res["success"], "Tuna strike must succeed")
	assert(sim.trick_cooldowns["tuna_strike"] > 0, "Trick must be placed on cooldown")

	# Second call while on cooldown must fail
	var cd_res = sim.use_trick("tuna_strike", target_pos)
	assert(not cd_res["success"], "Cannot cast trick on cooldown")
	print("[PASS] Tuna Strike activation and cooldown tracking verified")

	# 5. TEST NIGHT LANTERN TRICK (SHADOW REVEAL)
	var shadow_u = sim.spawn_unit({"coat": "rust", "shadow": true}, 20.0)
	assert(not shadow_u.can_be_targeted(false), "Shadow mouse cannot be targeted without night eye")

	var lantern_res = sim.use_trick("night_lantern", target_pos)
	assert(lantern_res["success"], "Night lantern activation succeeds")
	assert(sim.lantern_reveal_time > 0.0, "Lantern duration is active")

	# Verify targeting works via match._find_target with lantern active
	var found = sim._find_target(Vector2(200, 200), 500.0, false, SimConstants.TargetPriority.FIRST, false)
	assert(found != null, "Shadow unit is targetable while Lantern is active")
	print("[PASS] Night Lantern global shadow illumination verified")

	# 6. TEST CATNIP FRENZY TRICK
	var pip_tower = sim.place_tower("pip", Vector2(200, 200))
	var base_spd = pip_tower.aura_speed_mult
	var frenzy_res = sim.use_trick("catnip_frenzy", target_pos)
	assert(frenzy_res["success"], "Catnip Frenzy succeeds")
	assert(pip_tower.aura_speed_mult > base_spd, "Catnip frenzy increases cat attack speed")
	print("[PASS] Catnip Frenzy attack speed boost verified")

	# 7. TEST YARN SNARE TRICK (CONTROL & IMMUNITY)
	var snare_res = sim.use_trick("yarn_snare", target_pos)
	assert(snare_res["success"], "Yarn snare succeeds")
	assert(mat_unit.status.stun_time == 0.0, "Matriarch must ignore stun from yarn snare")
	assert(mat_unit.status.slows.is_empty(), "Matriarch must ignore slow from yarn snare")
	print("[PASS] Yarn Snare control and Rat Matriarch immunity verified")

	# 8. TEST BARE PAW MODE RESTRICTION
	var bp_sim = SimMatch.new()
	bp_sim.setup(
		SimConstants.GameMode.BARE_PAW,
		1337,
		mice_data,
		rats_data,
		{"pip": pip_data},
		{},
		camp_data
	)
	bp_sim.load_tricks_data(tricks_data)
	var bp_res = bp_sim.use_trick("tuna_strike", target_pos)
	assert(not bp_res["success"], "Tricks must fail in Bare Paw mode")
	assert(bp_res["reason"] == "bare_paw", "Reason must be bare_paw")
	print("[PASS] Bare Paw trick restriction verified (No tricks allowed in Bare Paw)")

	print("==================================================")
	print("   ALL TRICKS & CAMPAIGN TESTS PASSED CLEANLY!    ")
	print("==================================================")
	quit(0)
