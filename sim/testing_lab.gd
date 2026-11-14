# An isolated, headless wrapper around a normal match for experimentation.
# It never commits a result or mutates a profile.
class_name SimTestingLab
extends RefCounted

const SimMatch = preload("res://sim/match.gd")

var match_sim: SimMatch
var paused: bool = false
var sample_start_tick: int = 0
var sample_start_hp_removed: int = 0

func setup(p_match: SimMatch) -> bool:
	if p_match == null or p_match.economy == null or p_match.replay == null:
		return false
	match_sim = p_match
	paused = false
	reset_dps_sample(false)
	return true

func set_unlimited_kibble(enabled: bool, record_action: bool = true) -> void:
	match_sim.economy.unlimited_kibble = enabled
	if record_action:
		match_sim.replay.log_action(match_sim.tick_counter, "lab_unlimited_kibble", {"enabled": enabled})

func set_paused(enabled: bool, record_action: bool = true) -> void:
	paused = enabled
	if record_action:
		match_sim.replay.log_action(match_sim.tick_counter, "lab_pause", {"enabled": enabled})

func advance() -> void:
	if not paused:
		match_sim.tick()

func step(record_action: bool = true) -> bool:
	if not paused or match_sim.match_won or match_sim.match_lost:
		return false
	if record_action:
		match_sim.replay.log_action(match_sim.tick_counter, "lab_step")
	match_sim.tick()
	return true

# Only authored rounds are accepted. Start through the normal match code so
# its spawning, income, and between-round mechanics remain authoritative.
func start_round(round_number: int, record_action: bool = true) -> bool:
	if match_sim.round_in_progress or match_sim.match_won or match_sim.match_lost:
		return false
	if round_number < 1 or round_number > match_sim.max_rounds:
		return false
	if not match_sim.round_data.get("rounds", {}).has(str(round_number)):
		return false
	match_sim.current_round = round_number - 1
	if record_action:
		match_sim.replay.log_action(match_sim.tick_counter, "lab_select_round", {"round": round_number})
	return match_sim.start_next_round()

func spawn_enemy(kind: String, enemy_id: String, path_index: int = 0, record_action: bool = true) -> bool:
	if match_sim.match_won or match_sim.match_lost or path_index < 0 or path_index >= match_sim.paths.size():
		return false
	var config := {"path_index": path_index}
	if kind == "mouse" and match_sim.mice_data.get("coats", {}).has(enemy_id):
		config["coat"] = enemy_id
	elif kind == "rat" and match_sim.rats_data.get("rats", {}).has(enemy_id):
		config["rat"] = enemy_id
	else:
		return false
	match_sim.spawn_unit(config)
	if record_action:
		match_sim.replay.log_action(match_sim.tick_counter, "lab_spawn", {"kind": kind, "id": enemy_id, "path_index": path_index})
	return true

func reset_dps_sample(record_action: bool = true) -> void:
	sample_start_tick = match_sim.tick_counter
	sample_start_hp_removed = match_sim.total_hp_removed
	if record_action:
		match_sim.replay.log_action(match_sim.tick_counter, "lab_reset_dps")

func get_dps_sample() -> Dictionary:
	var elapsed_ticks := match_sim.tick_counter - sample_start_tick
	var removed := match_sim.total_hp_removed - sample_start_hp_removed
	return {
		"elapsed_ticks": elapsed_ticks,
		"hp_removed": removed,
		"dps": 0.0 if elapsed_ticks <= 0 else float(removed) * 30.0 / float(elapsed_ticks)
	}

# Applies a recorded lab command without recording it a second time. The normal
# replay driver remains responsible for delivering actions at their stored tick.
func apply_replay_action(action: Dictionary) -> bool:
	var payload: Dictionary = action.get("payload", {})
	match str(action.get("type", "")):
		"lab_unlimited_kibble":
			set_unlimited_kibble(bool(payload.get("enabled", false)), false)
			return true
		"lab_pause":
			set_paused(bool(payload.get("enabled", false)), false)
			return true
		"lab_step":
			return step(false)
		"lab_select_round":
			return start_round(int(payload.get("round", 0)), false)
		"lab_spawn":
			return spawn_enemy(str(payload.get("kind", "")), str(payload.get("id", "")), int(payload.get("path_index", 0)), false)
		"lab_reset_dps":
			reset_dps_sample(false)
			return true
	return false
