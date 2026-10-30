# Clowder: Alley Siege - Replay & Action Logger
class_name SimReplay
extends RefCounted

const SimConstants = preload("res://sim/constants.gd")

var match_seed: int = 0
var map_id: String = "sunny_gutter"
var mode: int = SimConstants.GameMode.SUNNY
var actions: Array[Dictionary] = []

func setup(p_seed: int, p_map: String, p_mode: int) -> void:
	match_seed = p_seed
	map_id = p_map
	mode = p_mode
	actions.clear()

func log_action(tick: int, action_type: String, payload: Dictionary = {}) -> void:
	actions.append({
		"tick": tick,
		"type": action_type,
		"payload": payload
	})

func to_dict() -> Dictionary:
	return {
		"version": 1,
		"seed": match_seed,
		"map": map_id,
		"mode": mode,
		"actions": actions
	}

func load_from_dict(data: Dictionary) -> void:
	match_seed = int(data.get("seed", 0))
	map_id = data.get("map", "sunny_gutter")
	mode = int(data.get("mode", SimConstants.GameMode.SUNNY))
	actions = data.get("actions", []).duplicate(true)

