# Clowder: Alley Siege - Replay & Action Logger
class_name SimReplay
extends RefCounted

const SimConstants = preload("res://sim/constants.gd")

var match_seed: int = 0
var map_id: String = "sunny_gutter"
var map_revision: int = 1
var mode: int = SimConstants.GameMode.SUNNY
var actions: Array[Dictionary] = []

func setup(p_seed: int, p_map: String, p_mode: int, p_map_revision: int = 1) -> void:
	match_seed = p_seed
	map_id = p_map
	mode = p_mode
	map_revision = p_map_revision
	actions.clear()

func log_action(tick: int, action_type: String, payload: Dictionary = {}) -> void:
	actions.append({
		"tick": tick,
		"type": action_type,
		"payload": payload
	})

func to_dict() -> Dictionary:
	return {
		"version": 2,
		"seed": match_seed,
		"map": map_id,
		"map_revision": map_revision,
		"mode": mode,
		"actions": actions
	}

func load_from_dict(data: Dictionary) -> void:
	match_seed = int(data.get("seed", 0))
	map_id = data.get("map", "sunny_gutter")
	map_revision = int(data.get("map_revision", 1))
	mode = int(data.get("mode", SimConstants.GameMode.SUNNY))
	actions = data.get("actions", []).duplicate(true)

