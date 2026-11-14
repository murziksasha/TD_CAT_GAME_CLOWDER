# Connects an Alley Crawl run node to a normal authoritative SimMatch.
class_name SimAlleyCrawlSession
extends RefCounted

const SimAlleyCrawl = preload("res://sim/alley_crawl.gd")
const SimMatch = preload("res://sim/match.gd")

var run: SimAlleyCrawl

func setup(p_run: SimAlleyCrawl) -> bool:
	if p_run == null or p_run.get_current_node().is_empty() or p_run.completed or p_run.failed:
		return false
	run = p_run
	return true

func prepare_match(match_sim: SimMatch) -> bool:
	if match_sim == null or match_sim.economy == null or run == null:
		return false
	var effects := get_active_effects()
	var starter_percent := float(effects.get("starting_kibble_percent", 0.0))
	match_sim.economy.kibble = maxi(0, int(floor(float(match_sim.economy.kibble) * (1.0 + starter_percent / 100.0))) + run.banked_kibble)
	match_sim.lives = maxi(1, int(floor(float(match_sim.lives) * (1.0 + float(effects.get("starting_lives_percent", 0.0)) / 100.0))) + int(effects.get("district_start_lives", 0)))
	match_sim.max_lives = match_sim.lives
	match_sim.configure_expansion_effects(effects)
	return true

func get_active_effects() -> Dictionary:
	var effects: Dictionary = {}
	var node := run.get_current_node()
	for modifier_id in node.get("modifiers", []):
		_merge_effect(effects, run.config.get("modifiers", {}).get(modifier_id, {}))
	for relic_id in run.relics:
		_merge_effect(effects, run.config.get("relics", {}).get(relic_id, {}))
	for curse_id in run.curses:
		_merge_effect(effects, run.config.get("curses", {}).get(curse_id, {}))
	return effects

func _merge_effect(target: Dictionary, definition: Dictionary) -> void:
	var effect_id := str(definition.get("effect", ""))
	if effect_id.is_empty():
		return
	target[effect_id] = float(target.get(effect_id, 0.0)) + float(definition.get("value", 0.0))

func finish_district(match_sim: SimMatch) -> bool:
	if match_sim == null or not match_sim.match_won:
		return false
	return run.complete_district(match_sim.economy.kibble)
