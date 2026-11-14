extends SceneTree

const AlleyCrawl = preload("res://sim/alley_crawl.gd")
const SaveManager = preload("res://sim/save_manager.gd")
const Session = preload("res://sim/alley_crawl_session.gd")
const Match = preload("res://sim/match.gd")
const Constants = preload("res://sim/constants.gd")

func load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}

func _init() -> void:
	var config := load_json("res://content/grand_expansion/alley_crawl.json")
	var first := AlleyCrawl.new()
	var second := AlleyCrawl.new()
	assert(first.setup(884422, config) and second.setup(884422, config))
	assert(first.to_dict() == second.to_dict(), "Same seed must generate the same expedition")
	assert(first.stage_count >= 5 and first.stage_count <= 7)
	assert(first.get_next_nodes().size() == 2)
	assert(first.complete_district(999))
	assert(first.banked_kibble == 249)
	assert(first.pending_relic_offer.size() == 3)
	var offered := first.pending_relic_offer[0]
	assert(first.choose_relic(offered, true))
	var next_id := str(first.get_next_nodes()[0].id)
	assert(first.choose_next_node(next_id))
	var saved := first.to_dict()
	var restored := AlleyCrawl.new()
	assert(restored.load_from_dict(saved, config))
	assert(restored.to_dict() == saved, "Save/reload must preserve graph, choices, draft RNG, and bank")
	var profile := SaveManager.new()
	assert(profile.store_alley_crawl_run(saved))
	var profile_restored := AlleyCrawl.new()
	assert(profile_restored.load_from_dict(profile.get_alley_crawl_run(), config))
	assert(profile_restored.to_dict() == saved)
	for node in restored.nodes:
		assert(node.modifiers.size() <= 2)
		assert(not ("dense_fog" in node.modifiers and "clear_morning" in node.modifiers))
	assert(not restored.choose_next_node("missing"))
	restored.banked_kibble = 25
	restored.relics = ["golden_whisker", "catnip_satchel"]
	var session := Session.new()
	assert(session.setup(restored))
	var match_sim := Match.new()
	match_sim.setup(Constants.GameMode.SUNNY, 99, load_json("res://content/mice.json"), load_json("res://content/rats.json"), {}, {}, load_json("res://content/rounds/sunny.json"))
	var base_kibble := match_sim.economy.kibble
	assert(session.prepare_match(match_sim))
	assert(match_sim.economy.kibble >= base_kibble + 25)
	assert(match_sim.economy.ruleset_pop_income_multiplier >= 1.08)
	print("[PASS] Alley Crawl deterministic graph, draft, carry-over, and reload")
	quit(0)
