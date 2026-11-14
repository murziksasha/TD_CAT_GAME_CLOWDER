extends SceneTree

const SimSaveManager = preload("res://sim/save_manager.gd")

func _init() -> void:
	print("==================================================")
	print("      CLOWDER: SAVE MANAGER & METAPROGRESSION     ")
	print("==================================================")

	var mgr = SimSaveManager.new()

	# 1. TEST DEFAULT PROFILE
	var def = mgr.get_default_profile()
	assert(def["account"]["level"] == 1, "Initial level must be 1")
	assert(def["economy"]["fishcoin"] == 0, "Initial fishcoin must be 0")
	assert(def["economy"]["golden_bones"] == 0, "Initial golden bones must be 0")
	assert(def["expansion_runs"]["alley_crawl"] == null, "No Alley Crawl is active on a fresh profile")
	print("[PASS] Default profile schema verified")

	var crawl_state := {"schema_version": 1, "seed": 7711, "current_stage": 2}
	assert(mgr.store_alley_crawl_run(crawl_state))
	var loaded_crawl := mgr.get_alley_crawl_run()
	assert(loaded_crawl == crawl_state)
	loaded_crawl["current_stage"] = 9
	assert(mgr.get_alley_crawl_run().current_stage == 2, "Callers cannot mutate stored run state by reference")
	mgr.clear_alley_crawl_run()
	assert(mgr.get_alley_crawl_run().is_empty())
	assert(not mgr.store_alley_crawl_run({"schema_version": 99}))
	var reward_config := {"completion_fishcoin": 20, "curse_fishcoin_cap": 40, "curses": {"risk": {"fishcoin": 12}}}
	var reward_run := {"completed": true, "generator_version": 1, "seed": 123, "curses": ["risk"]}
	var fish_before_crawl := int(mgr.data.economy.fishcoin)
	var crawl_reward := mgr.claim_alley_crawl_completion(reward_run, reward_config)
	assert(crawl_reward.success and crawl_reward.fishcoin == 32)
	assert(int(mgr.data.economy.fishcoin) == fish_before_crawl + 32)
	assert(not mgr.claim_alley_crawl_completion(reward_run, reward_config).success, "Crawl result pays once")
	print("[PASS] Alley Crawl run persistence is versioned and copy-safe")

	# 2. TEST SAVE & LOAD INTEGRITY
	assert(mgr.save_profile(), "save_profile must succeed")
	assert(mgr.load_profile(), "load_profile must succeed")
	assert(mgr.data["account"]["level"] == 1, "Loaded level matches")
	print("[PASS] Atomic save and SHA-256 checksum load verified")

	# 3. TEST TAMPER DETECTION
	var content = FileAccess.get_file_as_string(SimSaveManager.SAVE_PATH)
	var tampered = content.replace('"level": 1', '"level": 99')
	var f = FileAccess.open(SimSaveManager.SAVE_PATH, FileAccess.WRITE)
	f.store_string(tampered)
	f.close()

	var corrupted_mgr = SimSaveManager.new()
	var loaded = corrupted_mgr.load_profile()
	# Checksum failed, should safely revert to default profile level 1
	assert(corrupted_mgr.data["account"]["level"] == 1, "Tampered profile must reset to safe default")
	print("[PASS] Tamper detection and safe default recovery verified")

	# Restore fresh profile
	mgr = SimSaveManager.new()
	mgr.save_profile()

	# 4. TEST ACCOUNT XP & LEVEL UP (GATE 9 PARITY)
	var levels_file = FileAccess.open("res://content/levels.json", FileAccess.READ)
	var levels_data: Dictionary = JSON.parse_string(levels_file.get_as_text())
	levels_file.close()

	# Sunny 40 rounds sum = 2440 XP
	var sunny_xp = 0
	for r in range(1, 41):
		sunny_xp += int(20 + 2 * r)
	assert(sunny_xp == 2440, "Sunny XP sum must be 2440")

	var xp_res = mgr.add_account_xp(sunny_xp, levels_data)
	assert(xp_res["new_level"] in [9, 10, 11], "Reaches level 9-11 on first sunny clear")
	assert(mgr.data["account"]["insight_points"] >= 8, "Must have gained insight points")
	assert(mgr.data["economy"]["fishcoin"] >= 120, "Level ups must grant fishcoin (+15 each)")
	assert(mgr.data["unlock_queue"].size() > 0, "Unlock queue must contain enqueued rewards")
	print("[PASS] Account XP curve and Level 10 Sunny gate verified")

	# 5. TEST UNLOCK QUEUE CEREMONY PACING
	var initial_q_size = mgr.data["unlock_queue"].size()
	var ceremony = mgr.drain_unlock_queue(2, 1, 1)
	assert(ceremony["cats"].size() <= 2, "Max 2 cats per ceremony")
	assert(ceremony["heroes"].size() <= 1, "Max 1 hero per ceremony")
	assert(ceremony["maps"].size() <= 1, "Max 1 map per ceremony")
	print("[PASS] Unlock queue ceremony pacing verified (revealed cats: %s, heroes: %s, maps: %s)" % [
		str(ceremony["cats"]), str(ceremony["heroes"]), str(ceremony["maps"])
	])

	# 6. TEST CAT MASTERY & RANK 10 CEREMONY
	assert(mgr.get_mastery_rank("pip") == 1, "Initial rank is 1")
	assert(mgr.is_tier_unlocked("pip", 1), "Tier 1 unlocked at Rank 1")
	assert(mgr.is_tier_unlocked("pip", 2), "Tier 2 unlocked at Rank 1")
	assert(not mgr.is_tier_unlocked("pip", 3), "Tier 3 locked at Rank 1")

	# Add 450 XP -> Rank 2
	mgr.add_cat_mastery_xp("pip", 450)
	assert(mgr.get_mastery_rank("pip") == 2, "Rank 2 reached at 450 XP")
	assert(mgr.is_tier_unlocked("pip", 3), "Tier 3 unlocked at Rank 2")

	# Advance to Rank 10 (23000 XP)
	var bones_before = mgr.data["economy"]["golden_bones"]
	var r10_res = mgr.add_cat_mastery_xp("pip", 23000)
	assert(r10_res["new_rank"] == 10, "Rank 10 reached")
	assert(r10_res["gained_rank10"] == true, "Rank 10 ceremony triggered")
	assert(mgr.data["economy"]["golden_bones"] == bones_before + 5, "Rank 10 awards +5 Golden Bones")

	# Second call does not award duplicate Golden Bones
	var r10_repeat = mgr.add_cat_mastery_xp("pip", 1000)
	assert(r10_repeat["gained_rank10"] == false, "Rank 10 Golden Bones awarded only once")
	print("[PASS] Cat Mastery ranks (1-10) and +5 Golden Bones reward verified")

	# 7. TEST PRESTIGE SHOP ITEM PURCHASE
	var prestige_file = FileAccess.open("res://content/prestige_shop.json", FileAccess.READ)
	var prestige_data: Dictionary = JSON.parse_string(prestige_file.get_as_text())
	prestige_file.close()

	assert(prestige_data["items"].size() >= 5, "Prestige shop must contain items")
	var sample_item = prestige_data["items"][0] # "pip_golden_dandy", cost 25

	# Try to buy without enough golden bones
	assert(not mgr.buy_shop_item(sample_item["id"], sample_item["price"], true), "Cannot buy if poor")

	# Add required golden bones
	mgr.add_golden_bones(30)
	assert(mgr.buy_shop_item(sample_item["id"], sample_item["price"], true), "Purchase succeeds with enough golden bones")
	assert(mgr.is_item_owned(sample_item["id"]), "Item is now marked owned")
	assert(not mgr.buy_shop_item(sample_item["id"], sample_item["price"], true), "Cannot re-buy already owned item")
	print("[PASS] Collector's Vault (Golden Bones) purchase verified")

	# 8. TEST MATCH COMPLETION REWARDS FOR HIGH MODES
	# Alley victory -> +80 Fishcoin, +1 Golden Bone
	var bones_pre = mgr.data["economy"]["golden_bones"]
	var fish_pre = mgr.data["economy"]["fishcoin"]
	var match_res = mgr.record_match_completion(
		"sunny_gutter",
		1, # Alley
		60,
		true,
		{"pip": 5000, "nibs": 3000},
		levels_data,
		0
	)
	assert(match_res["fishcoin_gained"] == 80, "Alley first clear awards 80 fishcoin")
	assert(match_res["golden_bones_gained"] == 1, "Alley first clear awards 1 Golden Bone")
	assert(mgr.data["economy"]["golden_bones"] == bones_pre + 1, "Golden bones updated in profile")

	# Bare Paw victory -> +200 Fishcoin, +5 Golden Bones
	bones_pre = mgr.data["economy"]["golden_bones"]
	var bp_res = mgr.record_match_completion(
		"sunny_gutter",
		4, # Bare Paw
		40,
		true,
		{"pip": 4000},
		levels_data,
		0
	)
	assert(bp_res["fishcoin_gained"] == 200, "Bare Paw first clear awards 200 fishcoin")
	assert(bp_res["golden_bones_gained"] == 5, "Bare Paw first clear awards 5 Golden Bones")
	assert(mgr.data["economy"]["golden_bones"] == bones_pre + 5, "Bare Paw Golden Bones updated")
	print("[PASS] Mode completion rewards (Alley & Bare Paw Golden Bones) verified")

	# 9. TEST DAILY CHALLENGE GENERATION & CLAIM
	var challenge = mgr.get_daily_challenge("2026-11-14")
	assert(challenge["reward_golden_bones"] == 1, "Daily awards 1 Golden Bone")
	assert(challenge["reward_fishcoin"] == 30, "Daily awards 30 fishcoin")
	assert(not challenge["claimed"], "Initially unclaimed")

	var claim_res = mgr.claim_daily_challenge("2026-11-14")
	assert(claim_res["success"], "Claim succeeds")
	var repeat_claim = mgr.claim_daily_challenge("2026-11-14")
	assert(not repeat_claim["success"], "Cannot claim twice on same day")
	print("[PASS] Daily Challenge generation and claim verified")

	print("==================================================")
	print("   ALL SAVE MANAGER & PROGRESSION TESTS PASSED!   ")
	print("==================================================")
	quit(0)
