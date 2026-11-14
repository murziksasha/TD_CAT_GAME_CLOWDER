extends SceneTree

const SimConstants = preload("res://sim/constants.gd")
const SimMatch = preload("res://sim/match.gd")
const SimStatus = preload("res://sim/status.gd")
const SimUnit = preload("res://sim/unit.gd")

func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}

func _init() -> void:
	var mice := _load_json("res://content/mice.json")
	var rats := _load_json("res://content/rats.json")
	var rounds := _load_json("res://content/rounds/sunny.json")
	var map_data := _load_json("res://content/maps/sunny_gutter.json")
	var cats := {
		"pip": _load_json("res://content/cats/pip.json"),
		"bub": _load_json("res://content/cats/bub.json")
	}

	# Corrosion uses integer packets with a carried fractional remainder.
	var status := SimStatus.new()
	status.setup()
	status.apply_corrosion(3.0, 2.0, 7)
	var corrosion_total := 0
	for _i in range(60):
		for packet in status.tick(SimConstants.TICK_DELTA).get("damage_packets", []):
			corrosion_total += int(packet.amount)
	assert(corrosion_total == 6, "3 DPS for 2 seconds must deal exactly 6 damage")

	var matriarch_status := SimStatus.new()
	matriarch_status.setup("matriarch", true)
	matriarch_status.apply_corrosion(100.0, 1.0, 8)
	var matriarch_total := 0
	for _i in range(30):
		for packet in matriarch_status.tick(SimConstants.TICK_DELTA).get("damage_packets", []):
			matriarch_total += int(packet.amount)
	assert(matriarch_total == 15, "Matriarch Corrosion must be capped at 15 DPS")

	for coat in ["iron", "ink", "soot", "frost"]:
		var unit := SimUnit.new()
		unit.setup_mouse(1, coat, mice)
		var hit := unit.hit(1, SimConstants.DamageType.ACID)
		assert(hit.blocked_by == "" and hit.damage_dealt == 1, "Acid must bypass %s coat immunity" % coat)

	var sim := SimMatch.new()
	sim.setup(SimConstants.GameMode.SUNNY, 4242, mice, rats, cats, {}, rounds, 0, map_data)
	sim.economy.kibble = 999999
	var bub = sim.place_tower("bub", Vector2(180, 220))
	var pip = sim.place_tower("pip", Vector2(300, 220))
	assert(bub != null and pip != null, "Bub and Pip placement must succeed")
	for _i in range(3):
		assert(sim.upgrade_tower(bub, "path_b"), "Bub Brew upgrade must succeed")
	assert(sim.assign_brew(bub, pip), "Brew assignment between rounds must succeed")
	assert(pip.brew_speed_mult >= 0.10 and pip.brew_range_mult >= 0.10, "Taster's Brew stats must apply")
	sim.round_in_progress = true
	assert(not sim.assign_brew(bub, pip), "Brew reassignment during a round must fail")
	sim.round_in_progress = false
	sim.sell_tower(bub)
	assert(pip.brew_speed_mult == 0.0 and pip.brew_range_mult == 0.0, "Selling Bub must remove Brew")

	var midas_bub = sim.place_tower("bub", Vector2(460, 220))
	assert(sim.upgrade_tower(midas_bub, "path_c"), "Copper Flask must upgrade")
	var before := sim.economy.kibble
	sim._award_bub_midas(midas_bub, 1000, 100.0)
	assert(sim.economy.kibble - before == 40, "Copper Flask must stop at its 40 Kibble round cap")
	assert(midas_bub.midas_kibble_this_round == 40, "Midas cap tracking must be authoritative")
	sim.start_next_round()
	assert(midas_bub.midas_kibble_this_round == 0, "Midas cap must reset at round start")

	var meltdown_sim := SimMatch.new()
	meltdown_sim.setup(SimConstants.GameMode.SUNNY, 5151, mice, rats, cats, {}, rounds, 0, map_data)
	meltdown_sim.economy.kibble = 999999
	var meltdown = meltdown_sim.place_tower("bub", Vector2(180, 220))
	for _i in range(5):
		assert(meltdown_sim.upgrade_tower(meltdown, "path_a"), "Meltdown path upgrade must succeed")
	for _i in range(5):
		meltdown_sim._fire_bub_attack(meltdown, Vector2(300, 100))
	assert(bool(meltdown_sim.projectiles[-1].payload.get("spawn_puddle", false)), "Every fifth Meltdown attack must carry a puddle")

	var sheet: Texture2D = load("res://presentation/art/cats/bub_sheet.png")
	assert(sheet != null and sheet.get_width() == 1280 and sheet.get_height() == 128, "Bub sheet must be 10 transparent 128px cells")
	print("[PASS] Bub Acid, Corrosion, Brew, Midas, Meltdown, and art verified.")
	quit(0)
