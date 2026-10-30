# Clowder: Alley Siege - Unit (Mouse or Rat)
class_name SimUnit
extends RefCounted

const SimConstants = preload("res://sim/constants.gd")
const SimStatus = preload("res://sim/status.gd")

var id: int = 0
var is_rat: bool = false
var unit_type: String = "" # e.g. "rust", "porcelain", "burrow"
var spawn_coat: String = ""

# Path progress
var path_id: String = "main_loop"
var s: float = 0.0 # distance along path

# Combat stats
var speed_multiplier: float = 1.0
var base_speed: float = 40.0
var layer_hp: int = 1
var max_layer_hp: int = 1
var body_hp: int = 0
var max_body_hp: int = 0

# Properties
var is_shadow: bool = false
var is_gnaw: bool = false
var gnaw_timer: float = 0.0
var gnaw_regrows_left: int = 3
var is_plated: bool = false
var is_super: bool = false

# Status & Immunities
var immunities: Array = []
var status: SimStatus
var revealed_timer: float = 0.0
var is_alive: bool = true

# Parent reference / configs (injected or static)
var mice_data: Dictionary = {}
var rats_data: Dictionary = {}

func setup_mouse(
	p_id: int,
	coat: String,
	p_mice_data: Dictionary,
	p_is_shadow: bool = false,
	p_is_gnaw: bool = false,
	p_is_plated: bool = false,
	p_is_super: bool = false
) -> void:
	id = p_id
	is_rat = false
	unit_type = coat
	spawn_coat = coat
	mice_data = p_mice_data
	is_shadow = p_is_shadow
	is_gnaw = p_is_gnaw
	is_plated = p_is_plated
	is_super = p_is_super
	
	status = SimStatus.new()
	status.setup("", false)
	
	_apply_mouse_coat_data(coat)

func setup_rat(
	p_id: int,
	p_rat_type: String,
	p_rats_data: Dictionary,
	p_mice_data: Dictionary,
	p_is_plated: bool = false,
	sunny_reduced: bool = false,
	p_is_super: bool = false
) -> void:
	id = p_id
	is_rat = true
	unit_type = p_rat_type
	rats_data = p_rats_data
	mice_data = p_mice_data
	is_plated = p_is_plated
	is_super = p_is_super
	
	status = SimStatus.new()
	status.setup(p_rat_type, p_rat_type == "matriarch")
	
	var rinfo: Dictionary = rats_data.get("rats", {}).get(p_rat_type, {})
	base_speed = 40.0 * float(rinfo.get("speed_multiplier", 1.0))
	
	var hp = int(rinfo.get("body_hp", 200))
	if sunny_reduced and rinfo.has("sunny_r40_hp"):
		hp = int(rinfo.get("sunny_r40_hp", 130))
	if is_plated:
		hp *= 2
	body_hp = hp
	max_body_hp = hp
	layer_hp = body_hp
	max_layer_hp = body_hp
	
	immunities = rinfo.get("immunities", []).duplicate()
	if rinfo.get("shadow", false):
		is_shadow = true

func _apply_mouse_coat_data(coat: String) -> void:
	var coats: Dictionary = mice_data.get("coats", {})
	var cdata: Dictionary = coats.get(coat, {})
	base_speed = 40.0 * float(cdata.get("speed_multiplier", 1.0))
	immunities = cdata.get("immunities", []).duplicate()
	
	var lhp = int(cdata.get("layer_hp", 1))
	if coat == "porcelain" and is_super:
		lhp = int(mice_data.get("super_porcelain", {}).get("shell_hp", 60))
	if is_plated:
		lhp *= 2
	layer_hp = lhp
	max_layer_hp = lhp

func can_be_targeted(has_night_eye: bool) -> bool:
	if not is_shadow:
		return true
	return has_night_eye or revealed_timer > 0.0

func calculate_current_rbe() -> int:
	if is_rat:
		var rinfo: Dictionary = rats_data.get("rats", {}).get(unit_type, {})
		var base_rbe = int(rinfo.get("rbe", 0))
		if is_plated and rinfo.has("plated_rbe"):
			base_rbe = int(rinfo.get("plated_rbe", 0))
		# If damaged body HP
		var lost_body = max_body_hp - body_hp
		return max(1, base_rbe - lost_body)
	else:
		return _calc_mouse_rbe(unit_type, layer_hp, is_plated, is_super)

func _calc_mouse_rbe(coat: String, cur_layer_hp: int, plated: bool, super_mode: bool) -> int:
	var coats: Dictionary = mice_data.get("coats", {})
	var cdata: Dictionary = coats.get(coat, {})
	var rbe_sum = cur_layer_hp
	var children: Array = cdata.get("children", [])
	
	for child in children:
		var ccoat = child.get("coat", "")
		var count = int(child.get("count", 1))
		if super_mode and not is_rat:
			# In super mode, only 1 child spawns (primary)
			if not child.get("is_primary", true):
				continue
			count = 1
		var child_cdata = coats.get(ccoat, {})
		var child_base_hp = int(child_cdata.get("layer_hp", 1))
		rbe_sum += count * _calc_mouse_rbe(ccoat, child_base_hp, false, super_mode)
	return rbe_sum

# Returns Dictionary with details of pop, damage dealt, kibble earned, spawned children
func hit(
	raw_damage: int,
	damage_type: int,
	bonus_vs_porcelain: int = 0,
	bonus_vs_rats: int = 0,
	is_crit: bool = false
) -> Dictionary:
	var result = {
		"damage_dealt": 0,
		"hp_removed": 0,
		"killed": false,
		"overflow_damage": 0,
		"children_to_spawn": [],
		"shell_bounty": 0,
		"coat_popped": false
	}
	
	if not is_alive:
		return result
		
	# Immunity check
	if SimConstants.is_immune_to_damage(immunities, damage_type):
		return result
		
	# Damage calculation
	var effective_damage = raw_damage
	if is_rat:
		effective_damage += bonus_vs_rats
	elif unit_type == "porcelain":
		effective_damage += bonus_vs_porcelain
		
	# Frozen vulnerability: +1 from Bite & Blast
	if status.freeze_time > 0.0:
		if damage_type == SimConstants.DamageType.BITE or damage_type == SimConstants.DamageType.BLAST:
			effective_damage += 1
			
	# Mark damage amp
	effective_damage += status.mark_bonus
	
	if effective_damage <= 0:
		return result
		
	if is_rat:
		var dmg_applied = min(body_hp, effective_damage)
		body_hp -= dmg_applied
		result.hp_removed = dmg_applied
		result.damage_dealt = dmg_applied
		if body_hp <= 0:
			is_alive = false
			result.killed = true
			var rinfo = rats_data.get("rats", {}).get(unit_type, {})
			var death_spawns = rinfo.get("on_death", [])
			result.children_to_spawn = death_spawns.duplicate(true)
			# Plated rat spawns plated children
			if is_plated:
				for ch in result.children_to_spawn:
					ch["plated"] = true
	else:
		var dmg_applied = min(layer_hp, effective_damage)
		layer_hp -= dmg_applied
		result.hp_removed = dmg_applied
		result.damage_dealt = dmg_applied
		
		# Reset Gnaw timer on taking damage
		gnaw_timer = 0.0
		
		if layer_hp <= 0:
			result.coat_popped = true
			var remaining_dmg = effective_damage - dmg_applied
			result.overflow_damage = remaining_dmg
			
			# Super porcelain shell bounty
			if unit_type == "porcelain" and is_super:
				result.shell_bounty = int(mice_data.get("super_porcelain", {}).get("shell_bounty", 48))
				
			var coats = mice_data.get("coats", {})
			var cdata = coats.get(unit_type, {})
			var children = cdata.get("children", [])
			
			if children.is_empty():
				# Rust popped! Completely dead
				is_alive = false
				result.killed = true
			else:
				# Spawn children
				var spawns: Array[Dictionary] = []
				for ch in children:
					var ccoat = ch.get("coat", "")
					var count = int(ch.get("count", 1))
					if is_super:
						if not ch.get("is_primary", true):
							continue
						count = 1
					for _i in range(count):
						spawns.append({
							"coat": ccoat,
							"is_shadow": is_shadow,
							"is_gnaw": is_gnaw,
							"is_plated": false,
							"is_super": is_super
						})
				
				# First child replaces this unit; remainder are spawned as new units
				if not spawns.is_empty():
					var first = spawns[0]
					_transition_to_child(first.coat, first.is_shadow, first.is_gnaw, first.is_plated, is_super)
					
					# Pass remaining spawns
					for idx in range(1, spawns.size()):
						result.children_to_spawn.append(spawns[idx])
						
					# Recurse overflow on the first child in the same hit without extra pierce!
					if result.overflow_damage > 0 and is_alive:
						var sub_hit = hit(
							result.overflow_damage,
							damage_type,
							bonus_vs_porcelain,
							bonus_vs_rats,
							is_crit
						)
						result.damage_dealt += sub_hit.damage_dealt
						result.hp_removed += sub_hit.hp_removed
						result.shell_bounty += sub_hit.shell_bounty
						result.children_to_spawn.append_array(sub_hit.children_to_spawn)
						result.overflow_damage = sub_hit.overflow_damage
						if sub_hit.killed:
							result.killed = true
	return result

func _transition_to_child(new_coat: String, shadow: bool, gnaw: bool, plated: bool, super_m: bool) -> void:
	unit_type = new_coat
	is_shadow = shadow
	is_gnaw = gnaw
	is_plated = plated
	is_super = super_m
	_apply_mouse_coat_data(new_coat)

func tick(delta: float) -> Dictionary:
	var tick_res = status.tick(delta)
	
	if revealed_timer > 0.0:
		revealed_timer = maxf(0.0, revealed_timer - delta)
		
	# Apply DoTs from status
	if is_alive:
		if tick_res.burn_damage > 0.0:
			hit(int(ceil(tick_res.burn_damage)), tick_res.burn_type)
		if is_alive and tick_res.hex_damage > 0.0:
			hit(int(ceil(tick_res.hex_damage)), SimConstants.DamageType.MAGIC)
			
	# Gnaw regrow logic
	if is_alive and not is_rat and is_gnaw and gnaw_regrows_left > 0:
		var cur_speed_mult = status.get_speed_multiplier()
		# Only regrows while speed >= 80%
		if cur_speed_mult >= 0.8:
			gnaw_timer += delta
			if gnaw_timer >= 2.8:
				gnaw_timer = 0.0
				_try_gnaw_regrow()
				
	# Move along path
	if is_alive:
		var actual_speed = base_speed * status.get_speed_multiplier()
		s += actual_speed * delta
		
	return tick_res

func _try_gnaw_regrow() -> void:
	if unit_type == spawn_coat:
		return # Already at max spawn coat
	var coats = mice_data.get("coats", {})
	# Find parent coat whose child is this coat
	for parent_name in coats.keys():
		var pdata = coats[parent_name]
		var children = pdata.get("children", [])
		for ch in children:
			if ch.get("coat", "") == unit_type:
				_transition_to_child(parent_name, is_shadow, is_gnaw, false, is_super)
				gnaw_regrows_left -= 1
				return

