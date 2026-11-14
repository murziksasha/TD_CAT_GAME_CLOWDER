# Clowder: Alley Siege - Status Effect Manager
class_name SimStatus
extends RefCounted

const SimConstants = preload("res://sim/constants.gd")

var freeze_time: float = 0.0
var stun_time: float = 0.0
var slows: Array[Dictionary] = [] # {"factor": 0.5, "time": 2.0}

var burn_dps: float = 0.0
var burn_time: float = 0.0
var burn_type: int = SimConstants.DamageType.BITE
var burn_source_id: int = -1
var burn_accumulator: float = 0.0

var corrosion_dps: float = 0.0
var corrosion_time: float = 0.0
var corrosion_source_id: int = -1
var corrosion_accumulator: float = 0.0

var mark_bonus: int = 0
var mark_time: float = 0.0

var hex_dps: float = 0.0
var hex_time: float = 0.0
var hex_spread_count: int = 0
var hex_source_id: int = -1
var hex_accumulator: float = 0.0

var knockback_this_second: float = 0.0
var knockback_window: float = 0.0

var is_matriarch: bool = false
var rat_type: String = ""

func setup(p_rat_type: String = "", p_is_matriarch: bool = false) -> void:
	rat_type = p_rat_type
	is_matriarch = p_is_matriarch

func apply_freeze(duration: float) -> bool:
	if is_matriarch:
		return false
	var d = duration
	if rat_type == "monarch" or rat_type == "burrow" or rat_type == "bristle" or rat_type == "dusk":
		d = min(d, 0.6)
	freeze_time = max(freeze_time, d)
	return d > 0.0

func apply_stun(duration: float, mult: float = 1.0) -> bool:
	if is_matriarch:
		return false
	var d = duration * mult
	stun_time = max(stun_time, d)
	return d > 0.0

func apply_slow(factor: float, duration: float) -> bool:
	if is_matriarch:
		return false
	slows.append({"factor": clampf(factor, 0.05, 1.0), "time": duration})
	return duration > 0.0

func apply_burn(dps: float, duration: float, type: int = SimConstants.DamageType.BITE, source_id: int = -1) -> void:
	var final_dps = dps
	if is_matriarch:
		final_dps = minf(final_dps, 15.0)
	elif rat_type == "monarch" or rat_type == "bristle" or rat_type == "burrow":
		final_dps = minf(final_dps, 40.0)
	
	if final_dps > burn_dps:
		burn_accumulator = 0.0
		burn_dps = final_dps
		burn_type = type
		burn_source_id = source_id
		burn_time = max(burn_time, duration)
	elif is_equal_approx(final_dps, burn_dps):
		burn_type = type
		burn_source_id = source_id
		burn_time = max(burn_time, duration)
	else:
		burn_time = max(burn_time, duration)

func apply_corrosion(dps: float, duration: float, source_id: int = -1) -> void:
	var final_dps := dps
	if is_matriarch:
		final_dps = minf(final_dps, 15.0)
	elif rat_type in ["monarch", "bristle", "burrow", "dusk"]:
		final_dps = minf(final_dps, 40.0)
	if final_dps > corrosion_dps:
		corrosion_accumulator = 0.0
		corrosion_dps = final_dps
		corrosion_source_id = source_id
		corrosion_time = maxf(corrosion_time, duration)
	elif is_equal_approx(final_dps, corrosion_dps):
		corrosion_time = maxf(corrosion_time, duration)
	else:
		corrosion_time = maxf(corrosion_time, duration)

func apply_mark(bonus: int, duration: float) -> void:
	var final_bonus = bonus
	var final_dur = duration
	if is_matriarch:
		final_bonus = min(final_bonus, 1)
		final_dur = minf(final_dur, 3.0)
	
	if final_bonus > mark_bonus:
		mark_bonus = final_bonus
		mark_time = final_dur
	elif final_bonus == mark_bonus:
		mark_time = max(mark_time, final_dur)

func apply_hex(total_damage: float, duration: float, spread: int = 0, source_id: int = -1) -> void:
	var final_dmg = total_damage
	if is_matriarch:
		final_dmg = minf(final_dmg, 20.0)
		spread = 0
	var dps = final_dmg / maxf(duration, 0.1)
	if dps >= hex_dps:
		if dps > hex_dps:
			hex_accumulator = 0.0
		hex_dps = dps
		hex_time = max(hex_time, duration)
		hex_spread_count = max(hex_spread_count, spread)
		hex_source_id = source_id

func can_apply_knockback(amount: float, cap_per_sec: float = 150.0) -> float:
	if is_matriarch or rat_type == "monarch":
		return 0.0
	var allowed = maxf(0.0, cap_per_sec - knockback_this_second)
	var applied = minf(amount, allowed)
	knockback_this_second += applied
	return applied

func get_speed_multiplier() -> float:
	if freeze_time > 0.0 or stun_time > 0.0:
		return 0.0
	if is_matriarch:
		return 1.0
	var min_factor: float = 1.0
	for s in slows:
		if s.time > 0.0:
			min_factor = minf(min_factor, s.factor)
	return min_factor

func tick(delta: float) -> Dictionary:
	var damage_packets: Array[Dictionary] = []
	
	# Tick durations
	if freeze_time > 0.0:
		freeze_time = maxf(0.0, freeze_time - delta)
	if stun_time > 0.0:
		stun_time = maxf(0.0, stun_time - delta)
	
	# Clean expired slows
	var active_slows: Array[Dictionary] = []
	for s in slows:
		s.time -= delta
		if s.time > 0.0:
			active_slows.append(s)
	slows = active_slows
	
	# Burn
	if burn_time > 0.0:
		var step = minf(delta, burn_time)
		burn_accumulator += burn_dps * step
		var burn_damage := int(floor(burn_accumulator + 0.000001))
		if burn_damage > 0:
			burn_accumulator -= burn_damage
			damage_packets.append({"amount": burn_damage, "damage_type": burn_type, "effect": "burn", "source_tower_id": burn_source_id})
		burn_time -= delta
		if burn_time <= 0.0:
			burn_dps = 0.0
			burn_source_id = -1
			burn_accumulator = 0.0

	# Corrosion is Acid damage, never a control effect.
	if corrosion_time > 0.0:
		var corrosion_step := minf(delta, corrosion_time)
		corrosion_accumulator += corrosion_dps * corrosion_step
		var acid_damage := int(floor(corrosion_accumulator + 0.000001))
		if acid_damage > 0:
			corrosion_accumulator -= acid_damage
			damage_packets.append({"amount": acid_damage, "damage_type": SimConstants.DamageType.ACID, "effect": "corrosion", "source_tower_id": corrosion_source_id})
		corrosion_time -= delta
		if corrosion_time <= 0.0:
			corrosion_dps = 0.0
			corrosion_source_id = -1
			corrosion_accumulator = 0.0
			
	# Hex
	if hex_time > 0.0:
		var step = minf(delta, hex_time)
		hex_accumulator += hex_dps * step
		var hex_damage := int(floor(hex_accumulator + 0.000001))
		if hex_damage > 0:
			hex_accumulator -= hex_damage
			damage_packets.append({"amount": hex_damage, "damage_type": SimConstants.DamageType.MAGIC, "effect": "hex", "source_tower_id": hex_source_id})
		hex_time -= delta
		if hex_time <= 0.0:
			hex_dps = 0.0
			hex_spread_count = 0
			hex_source_id = -1
			hex_accumulator = 0.0
			
	# Mark
	if mark_time > 0.0:
		mark_time -= delta
		if mark_time <= 0.0:
			mark_bonus = 0
			
	# Knockback window decay
	knockback_window += delta
	if knockback_window >= 1.0:
		knockback_window = 0.0
		knockback_this_second = 0.0
		
	return {"damage_packets": damage_packets}

