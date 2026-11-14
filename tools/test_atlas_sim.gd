extends SceneTree

const SimConstants = preload("res://sim/constants.gd")
const SimMatch = preload("res://sim/match.gd")

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
	print("   CLOWDER: WARD ATLAS HEADLESS SIM TESTS")
	print("==================================================")
	
	var mice_data = _load_json("res://content/mice.json")
	var rats_data = _load_json("res://content/rats.json")
	var sunny_rounds = _load_json("res://content/rounds/sunny.json")
	var twin_gutters_map = _load_json("res://content/maps/twin_gutters.json")
	var stall_row_map = _load_json("res://content/maps/stall_row.json")
	var sunny_map = _load_json("res://content/maps/sunny_gutter.json")
	
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
		"mittens": _load_json("res://content/heroes/mittens.json")
	}
	
	# TEST 1: Twin Gutters Path B Leak
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
		twin_gutters_map
	)
	
	assert(sim.paths.size() == 2, "Twin gutters must have 2 paths")
	assert(sim.get_path_length(0) == 1150.0, "Path A length must be 1150")
	assert(sim.get_path_length(1) == 900.0, "Path B length must be 900")
	
	var initial_lives = sim.lives
	# Spawn mouse on Path B (index 1)
	var u = sim.spawn_unit({"coat": "rust", "path_index": 1}, 0.0)
	assert(u.path_index == 1, "Unit must be on path_index 1")
	assert(u.path_id == "path_b", "Unit path_id must be path_b")
	
	# Rust mouse speed is 40.0 u/s. 900 / 40 = 22.5s. At 30 Hz = 675 ticks.
	# Tick 680 ticks to ensure leak
	for i in range(680):
		sim.tick()
		if sim.lives < initial_lives:
			break
			
	assert(sim.lives == initial_lives - 1, "Lives should drop by 1 due to Rust mouse leak")
	var log = sim.drain_presentation_log()
	var found_leak = false
	for ev in log:
		if ev.get("type") == "leak" and ev.get("path_index") == 1:
			found_leak = true
			assert(ev.get("s") == 900.0, "Leak distance must match Path B length 900")
			break
	assert(found_leak, "Expected leak event on path_index 1")
	print("[PASS] Twin Gutters Path B leak verified at s=900.0 (lives: %d -> %d)." % [initial_lives, sim.lives])
	
	# TEST 2: Stall Row Sight Blocker
	var sim_stall = SimMatch.new()
	sim_stall.setup(
		SimConstants.GameMode.SUNNY,
		42,
		mice_data,
		rats_data,
		cat_bps,
		hero_bps,
		sunny_rounds,
		0,
		stall_row_map
	)
	assert(sim_stall.sight_blockers.size() >= 1, "Stall Row must have sight blockers")
	
	# Test LOS through stall at (400, 260, 90, 50)
	var cat_pos = Vector2(445.0, 360.0) # South of stall
	var mouse_pos = Vector2(445.0, 220.0) # North of stall on track
	assert(not sim_stall.has_line_of_sight(cat_pos, mouse_pos), "LOS should be blocked by stall")
	
	# Test LOS outside stall
	var open_pos = Vector2(200.0, 360.0)
	var open_mouse = Vector2(200.0, 220.0)
	assert(sim_stall.has_line_of_sight(open_pos, open_mouse), "LOS should be clear in open field")
	
	# Test placement blockage
	var place_check = sim_stall.can_place_tower_at("pip", Vector2(445.0, 280.0))
	assert(not place_check.valid, "Cannot place cat inside or overlapping stall prop")
	print("[PASS] Stall Row sight obstruction and placement clearance verified.")

	# TEST 3: Water-mask placement. Marlow is water-only; land cats remain off water.
	var sim_water = SimMatch.new()
	sim_water.setup(SimConstants.GameMode.SUNNY, 42, mice_data, rats_data, cat_bps, hero_bps, sunny_rounds, 0, sunny_map)
	var marlow_water = sim_water.can_place_tower_at("marlow", Vector2(800.0, 200.0))
	assert(marlow_water.valid, "Marlow must be placeable on Sunny Gutter water")
	assert(sim_water.place_tower("marlow", Vector2(800.0, 200.0)) != null, "Valid water placement must create Marlow")
	var pip_water = sim_water.can_place_tower_at("pip", Vector2(800.0, 200.0))
	assert(not pip_water.valid, "Land cats must not be placeable on water")
	var marlow_land = sim_water.can_place_tower_at("marlow", Vector2(160.0, 500.0))
	assert(not marlow_land.valid, "Marlow must not be placeable on land")
	print("[PASS] Authoritative water mask and Marlow placement verified.")
	
	# TEST 4: Schedule Querying (Fairness Gate 7)
	var sched = sim.get_upcoming_schedule(1, 3)
	assert(sched.size() == 3, "Schedule preview should return 3 rounds")
	assert(sched[0].round == 1, "Schedule preview starts at current round")
	print("[PASS] Three-round schedule visibility verified.")
	
	print("==================================================")
	print("   ALL ATLAS HEADLESS SIM TESTS PASSED CLEANLY")
	print("==================================================")
	quit(0)
