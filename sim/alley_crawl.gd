# Deterministic, headless Alley Crawl run state. Combat effects are applied by
# the match mode adapter; this class owns graph generation, choices, drafts,
# carry-over, and save/reload stability.
class_name SimAlleyCrawl
extends RefCounted

var seed: int = 0
var generator_version: int = 1
var stage_count: int = 5
var current_stage: int = 0
var current_node_id: String = ""
var completed: bool = false
var failed: bool = false
var banked_kibble: int = 0
var nodes: Array[Dictionary] = []
var chosen_node_ids: Array[String] = []
var relics: Array[String] = []
var curses: Array[String] = []
var pending_relic_offer: Array[String] = []
var pending_curse_offer: String = ""
var config: Dictionary = {}
var rng := RandomNumberGenerator.new()

func setup(p_seed: int, p_config: Dictionary) -> bool:
	if not _valid_config(p_config):
		return false
	seed = p_seed
	config = p_config.duplicate(true)
	generator_version = int(config.get("generator_version", 1))
	rng.seed = seed
	stage_count = rng.randi_range(int(config.stage_count_min), int(config.stage_count_max))
	current_stage = 0
	current_node_id = ""
	completed = false
	failed = false
	banked_kibble = 0
	chosen_node_ids.clear()
	relics.clear()
	curses.clear()
	pending_relic_offer.clear()
	pending_curse_offer = ""
	_generate_graph()
	return true

func _valid_config(value: Dictionary) -> bool:
	return int(value.get("schema_version", 0)) == 1 \
		and int(value.get("stage_count_min", 0)) >= 2 \
		and int(value.get("stage_count_max", 0)) >= int(value.get("stage_count_min", 0)) \
		and value.get("maps", []).size() >= 2 \
		and value.get("relics", {}).size() >= 3

func _generate_graph() -> void:
	nodes.clear()
	var maps: Array = config.maps.duplicate()
	maps.sort()
	for stage in range(stage_count):
		var choices := 1 if stage == 0 else (1 if stage == stage_count - 1 else 2)
		for choice in range(choices):
			var node_id := "s%d_%d" % [stage, choice]
			var modifiers := _draw_modifiers(stage)
			nodes.append({
				"id": node_id,
				"stage": stage,
				"map_id": str(maps[rng.randi_range(0, maps.size() - 1)]),
				"modifiers": modifiers,
				"next": []
			})
	for node in nodes:
		if int(node.stage) >= stage_count - 1:
			continue
		for candidate in nodes:
			if int(candidate.stage) == int(node.stage) + 1:
				node.next.append(candidate.id)
	current_node_id = "s0_0"
	chosen_node_ids.append(current_node_id)

func _draw_modifiers(stage: int) -> Array[String]:
	var eligible: Array[String] = []
	for id in config.modifiers.keys():
		if stage + 1 >= int(config.modifiers[id].get("min_stage", 1)):
			eligible.append(str(id))
	eligible.sort()
	var desired: int = mini(2, stage / 2)
	var result: Array[String] = []
	while result.size() < desired and not eligible.is_empty():
		var index := rng.randi_range(0, eligible.size() - 1)
		var candidate: String = eligible.pop_at(index)
		if _compatible_with(candidate, result):
			result.append(candidate)
	result.sort()
	return result

func _compatible_with(candidate: String, selected: Array[String]) -> bool:
	for pair in config.get("incompatibilities", []):
		if pair is Array and pair.size() == 2:
			if (candidate == str(pair[0]) and str(pair[1]) in selected) or (candidate == str(pair[1]) and str(pair[0]) in selected):
				return false
	return true

func get_current_node() -> Dictionary:
	for node in nodes:
		if str(node.id) == current_node_id:
			return node
	return {}

func get_next_nodes() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var current := get_current_node()
	for next_id in current.get("next", []):
		for node in nodes:
			if str(node.id) == str(next_id):
				result.append(node)
	return result

func complete_district(remaining_kibble: int) -> bool:
	if completed or failed or remaining_kibble < 0 or not pending_relic_offer.is_empty():
		return false
	banked_kibble = remaining_kibble / 4
	if current_stage >= stage_count - 1:
		completed = true
		return true
	_make_draft()
	return true

func _make_draft() -> void:
	var pool: Array[String] = []
	for id in config.relics.keys():
		if str(id) not in relics:
			pool.append(str(id))
	pool.sort()
	pending_relic_offer.clear()
	while pending_relic_offer.size() < 3 and not pool.is_empty():
		pending_relic_offer.append(pool.pop_at(rng.randi_range(0, pool.size() - 1)))
	var curse_pool: Array = config.get("curses", {}).keys()
	curse_pool.sort()
	pending_curse_offer = "" if curse_pool.is_empty() else str(curse_pool[rng.randi_range(0, curse_pool.size() - 1)])

func choose_relic(relic_id: String, take_curse: bool = false) -> bool:
	if relic_id not in pending_relic_offer:
		return false
	relics.append(relic_id)
	if take_curse and not pending_curse_offer.is_empty() and pending_curse_offer not in curses:
		curses.append(pending_curse_offer)
	pending_relic_offer.clear()
	pending_curse_offer = ""
	return true

func choose_next_node(node_id: String) -> bool:
	if completed or failed or not pending_relic_offer.is_empty():
		return false
	for node in get_next_nodes():
		if str(node.id) == node_id:
			current_node_id = node_id
			current_stage += 1
			chosen_node_ids.append(node_id)
			return true
	return false

func fail_run() -> void:
	if not completed:
		failed = true

func to_dict() -> Dictionary:
	return {
		"schema_version": 1,
		"seed": seed,
		"generator_version": generator_version,
		"stage_count": stage_count,
		"current_stage": current_stage,
		"current_node_id": current_node_id,
		"completed": completed,
		"failed": failed,
		"banked_kibble": banked_kibble,
		"nodes": nodes.duplicate(true),
		"chosen_node_ids": chosen_node_ids.duplicate(),
		"relics": relics.duplicate(),
		"curses": curses.duplicate(),
		"pending_relic_offer": pending_relic_offer.duplicate(),
		"pending_curse_offer": pending_curse_offer,
		"rng_state": rng.state
	}

func load_from_dict(data: Dictionary, p_config: Dictionary) -> bool:
	if int(data.get("schema_version", 0)) != 1 or not _valid_config(p_config):
		return false
	config = p_config.duplicate(true)
	seed = int(data.get("seed", 0))
	generator_version = int(data.get("generator_version", 0))
	if generator_version != int(config.get("generator_version", 1)):
		return false
	stage_count = int(data.get("stage_count", 0))
	current_stage = int(data.get("current_stage", 0))
	current_node_id = str(data.get("current_node_id", ""))
	completed = bool(data.get("completed", false))
	failed = bool(data.get("failed", false))
	banked_kibble = int(data.get("banked_kibble", 0))
	nodes.assign(data.get("nodes", []))
	chosen_node_ids.assign(data.get("chosen_node_ids", []))
	relics.assign(data.get("relics", []))
	curses.assign(data.get("curses", []))
	pending_relic_offer.assign(data.get("pending_relic_offer", []))
	pending_curse_offer = str(data.get("pending_curse_offer", ""))
	rng.seed = seed
	rng.state = int(data.get("rng_state", rng.state))
	return not get_current_node().is_empty() and current_stage >= 0 and current_stage < stage_count
