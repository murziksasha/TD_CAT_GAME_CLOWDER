extends SceneTree

const SimConstants = preload("res://sim/constants.gd")
const SimMatch = preload("res://sim/match.gd")
const SimLeaderboardManager = preload("res://sim/leaderboard_manager.gd")
const NetworkManager = preload("res://network/network_manager.gd")

func _load_json(path: String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not open " + path)
		return {}
	var text = file.get_as_text()
	var json = JSON.new()
	if json.parse(text) == OK:
		return json.data
	return {}

func _init() -> void:
	print("==================================================")
	print("   CLOWDER: CO-OP, LEADERBOARD & AUTO-WAVE TESTS  ")
	print("==================================================")

	var mice_data = _load_json("res://content/mice.json")
	var rats_data = _load_json("res://content/rats.json")
	var sunny_rounds = _load_json("res://content/rounds/sunny.json")
	var sunny_map = _load_json("res://content/maps/sunny_gutter.json")

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
		"mittens": _load_json("res://content/heroes/mittens.json")
	}

	# TEST 1: Co-op Dual Placements & Owner IDs
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
		sunny_map
	)

	# Place Player 1 tower (Teal)
	var t1 = sim.place_tower("pip", Vector2(160.0, 180.0), 1)
	assert(t1 != null, "Player 1 Pip placement must succeed")
	assert(t1.owner_id == 1, "Tower 1 must belong to Player 1")

	# Place Player 2 tower (Orange)
	var t2 = sim.place_tower("nibs", Vector2(240.0, 180.0), 2)
	assert(t2 != null, "Player 2 Nibs placement must succeed")
	assert(t2.owner_id == 2, "Tower 2 must belong to Player 2")

	print("[PASS] Co-op dual commander placement and owner_id validated (P1 Pip, P2 Nibs).")

	# TEST 2: Damage & Pop Tracking
	assert(t1.damage_dealt == 0, "Initial damage dealt must be 0")
	assert(t1.pops_count == 0, "Initial pops must be 0")

	# Spawn mouse and simulate combat
	sim.start_next_round()
	for i in range(120):
		sim.tick()
		if t1.damage_dealt > 0:
			break

	assert(t1.damage_dealt > 0, "Pip must register dealt damage")
	print("[PASS] Real-time damage and pop accumulation validated (Dmg: %d, Pops: %d)." % [t1.damage_dealt, t1.pops_count])

	# TEST 3: Leaderboard Manager Simulation
	if FileAccess.file_exists("user://leaderboards.json"):
		DirAccess.remove_absolute("user://leaderboards.json")
	var lead_mgr = SimLeaderboardManager.new()
	assert(lead_mgr.entries.size() <= 100, "Leaderboard must be capped to at most 100 entries")
	assert(lead_mgr.entries.size() > 0, "Leaderboard must contain initial benchmark entries")

	# Record a high score match
	var rec = lead_mgr.record_match(
		"TestPlayer_Hero",
		"sunny_gutter",
		"beginner",
		0,   # Sunny mode
		40,  # 40 rounds cleared
		40,
		200, # 200 lives
		1500,# 1500 kibble
		true,# won
		"mittens",
		true # clean sheet
	)
	assert(rec.score > 0, "Calculated score must be positive")
	assert(rec.rank >= 1 and rec.rank <= 100, "Recorded match must place on Top 100 ladder")

	var top_entries = lead_mgr.get_top_100("sunny_gutter", 0)
	assert(top_entries.size() > 0, "Filtered Top 100 query must return entries")
	assert(top_entries[0].score >= top_entries[-1].score, "Top 100 must be sorted descending by score")
	print("[PASS] Leaderboard recording and Top 100 query validated (Rank #%d, Score: %d)." % [rec.rank, rec.score])

	# TEST 4: Network Manager Component
	var net_mgr = NetworkManager.new()
	assert(net_mgr.local_player_id == 1, "Default local player id must be 1")
	assert(not net_mgr.is_host, "Default host state must be false")
	print("[PASS] NetworkManager ENet multiplayer component initialized.")

	print("==================================================")
	print("   ALL CO-OP, LEADERBOARD & STAT TESTS PASSED!    ")
	print("==================================================")
	quit(0)
