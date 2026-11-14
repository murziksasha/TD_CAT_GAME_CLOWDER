# Clowder: Alley Siege - Cat Tower Sim
class_name SimTower
extends RefCounted

const SimConstants = preload("res://sim/constants.gd")
const SimFeats = preload("res://sim/feats.gd")

var instance_id: int = 0
var owner_id: int = 1
var cat_id: String = ""
var cat_name: String = ""
var category: String = "Alley"
var position: Vector2 = Vector2.ZERO
var footprint_radius: float = 20.0
var placement_mask: Array = ["Land"]

# Upgrades
var tiers: Dictionary = {"path_a": 0, "path_b": 0, "path_c": 0}
var total_spent: int = 0

# Targeting
var target_priority: int = SimConstants.TargetPriority.FIRST

# Combat stats
var damage: int = 1
var damage_type: int = SimConstants.DamageType.CLAW
var pierce: int = 1
var range_radius: float = 130.0
var cooldown: float = 1.0
var projectile_speed: float = 400.0
var ruleset_range_mult: float = 0.0
var ruleset_speed_mult: float = 0.0
var ruleset_projectile_speed_mult: float = 0.0
var see_shadow: bool = false
var can_pop_iron: bool = false
var full_track_range: bool = false

# Support & Contribution tracking
var damage_dealt: int = 0
var pops_count: int = 0
var total_kibble_produced: int = 0
var total_buff_damage_assisted: float = 0.0
var buffed_cats_count: int = 0
var freeze_assists: int = 0

# Aura Buffs received from support cats
var aura_damage_bonus: int = 0
var aura_range_mult: float = 0.0
var aura_speed_mult: float = 0.0
var aura_pierce_bonus: int = 0
var aura_grant_night_eye: bool = false
var aura_crit_bonus: float = 0.0
var aura_sources: Array[int] = []

# Persistent support received from Bub. Recomputed by SimMatch so it never
# stacks additively with another Brew source.
var brew_damage_bonus: int = 0
var brew_range_mult: float = 0.0
var brew_speed_mult: float = 0.0
var brew_pierce_bonus: int = 0
var brew_source_id: int = -1

# Feat & Upgrade bonuses
var bonus_vs_porcelain: int = 0
var bonus_vs_rats: int = 0
var crit_chance: float = 0.0
var extra_projectiles: int = 0
var burn_dps_bonus: float = 0.0
var burn_duration_bonus: float = 0.0
var freeze_duration_bonus: float = 0.0
var slow_duration_bonus: float = 0.0
var explosion_radius_bonus: float = 0.0
var shatter_damage_bonus: int = 0
var hex_duration_bonus: float = 0.0
var hex_dps_bonus: float = 0.0
var extra_round_kibble: int = 0
var mark_duration_bonus: float = 0.0
var burst_shot_interval: int = 5
var cloud_duration_bonus: float = 0.0
var corrosion_duration_bonus: float = 0.0
var brew_primary_speed_bonus: float = 0.0
var midas_ratio_bonus: float = 0.0
var midas_cap_bonus: int = 0

# Internal cooldown / attack tracking
var attack_timer: float = 0.0
var shot_counter: int = 0
var successful_attacks: int = 0
var brew_target_id: int = -1
var midas_kibble_this_round: int = 0
var midas_fraction: float = 0.0

# Feats
var feat_xp: float = 0.0
var feat_rank: int = 0
var reroll_used: bool = false
var pending_feat_choice: bool = false
var selected_feats: Array[Dictionary] = []

# Raw data reference
var cat_data: Dictionary = {}

func setup(p_id: int, p_cat_data: Dictionary, pos: Vector2, initial_cost: int) -> void:
	instance_id = p_id
	cat_data = p_cat_data
	cat_id = cat_data.get("id", "")
	cat_name = cat_data.get("name", "")
	category = cat_data.get("category", "Alley")
	position = pos
	footprint_radius = float(cat_data.get("footprint_radius", 20.0))
	placement_mask = cat_data.get("placement_mask", ["Land"]).duplicate()
	total_spent = initial_cost
	
	_recalculate_stats()

func get_path_bits() -> int:
	return (tiers["path_a"] << 8) | (tiers["path_b"] << 4) | (tiers["path_c"])

func can_upgrade(path_key: String) -> bool:
	var current_tier = tiers.get(path_key, 0)
	if current_tier >= 5:
		return false
		
	# Check crosspath law:
	# 1. At most two paths can have upgrades (> 0)
	# 2. If one path is >= 3, other path cannot exceed 2
	var upgraded_paths = 0
	var other_path_above_2 = false
	for p in ["path_a", "path_b", "path_c"]:
		if tiers[p] > 0:
			upgraded_paths += 1
		if p != path_key and tiers[p] >= 3:
			other_path_above_2 = true
			
	if tiers[path_key] == 0 and upgraded_paths >= 2:
		return false
		
	if other_path_above_2 and current_tier >= 2:
		# If another path is >= 3 and this one is already 2, cannot go to 3
		return false
		
	return true

func get_crosspath_block_reason(path_key: String) -> String:
	var current_tier = tiers.get(path_key, 0)
	if current_tier >= 5:
		return "MAX_TIER"
	var upgraded_paths = 0
	var other_path_above_2 = false
	var blocking_path = ""
	for p in ["path_a", "path_b", "path_c"]:
		if tiers[p] > 0:
			upgraded_paths += 1
		if p != path_key and tiers[p] >= 3:
			other_path_above_2 = true
			blocking_path = p
	if tiers[path_key] == 0 and upgraded_paths >= 2:
		return "TWO_PATHS_CHOSEN"
	if other_path_above_2 and current_tier >= 2:
		return "LOCKED_BY_OTHER_TIER3:" + blocking_path
	return ""

func apply_aura_buffs(
	p_damage_bonus: int,
	p_range_mult: float,
	p_speed_mult: float,
	p_pierce_bonus: int,
	p_grant_night_eye: bool,
	p_crit_bonus: float,
	p_sources: Array[int]
) -> void:
	aura_damage_bonus = p_damage_bonus
	aura_range_mult = p_range_mult
	aura_speed_mult = p_speed_mult
	aura_pierce_bonus = p_pierce_bonus
	aura_grant_night_eye = p_grant_night_eye
	aura_crit_bonus = p_crit_bonus
	aura_sources = p_sources

func get_effective_damage() -> int:
	return damage + aura_damage_bonus + brew_damage_bonus

func get_effective_pierce() -> int:
	return pierce + aura_pierce_bonus + brew_pierce_bonus

func get_effective_range() -> float:
	return range_radius * (1.0 + aura_range_mult + brew_range_mult + ruleset_range_mult)

func get_effective_cooldown() -> float:
	return cooldown / maxf(0.1, 1.0 + aura_speed_mult + brew_speed_mult + ruleset_speed_mult)

func get_effective_projectile_speed() -> float:
	return projectile_speed * maxf(0.1, 1.0 + ruleset_projectile_speed_mult)

func get_effective_see_shadow() -> bool:
	return see_shadow or aura_grant_night_eye

func clear_brew_buff() -> void:
	brew_damage_bonus = 0
	brew_range_mult = 0.0
	brew_speed_mult = 0.0
	brew_pierce_bonus = 0
	brew_source_id = -1

func apply_brew_buff(damage_bonus: int, range_mult: float, speed_mult: float, pierce_bonus: int, source_id: int) -> void:
	brew_damage_bonus = maxi(brew_damage_bonus, damage_bonus)
	brew_range_mult = maxf(brew_range_mult, range_mult)
	brew_speed_mult = maxf(brew_speed_mult, speed_mult)
	brew_pierce_bonus = maxi(brew_pierce_bonus, pierce_bonus)
	if brew_source_id < 0:
		brew_source_id = source_id

func apply_upgrade(path_key: String, cost_paid: int) -> bool:
	if not can_upgrade(path_key):
		return false
	tiers[path_key] += 1
	total_spent += cost_paid
	_recalculate_stats()
	return true

func add_feat_xp(amount: float) -> void:
	var mult = 1.0
	for f in selected_feats:
		mult += float(f.get("feat_xp_mult", 0.0))
	feat_xp += amount * mult
	var new_rank = SimFeats.calculate_feat_rank(feat_xp)
	if new_rank > feat_rank:
		feat_rank = new_rank
		pending_feat_choice = true

func apply_feat(feat_card: Dictionary) -> void:
	selected_feats.append(feat_card)
	pending_feat_choice = false
	_recalculate_stats()

func _recalculate_stats() -> void:
	var base: Dictionary = cat_data.get("base", {})
	damage = int(base.get("damage", 1))
	damage_type = SimConstants.damage_type_from_string(base.get("damage_type", "Claw"))
	pierce = int(base.get("pierce", 1))
	range_radius = float(base.get("range", 130.0))
	cooldown = float(base.get("cooldown", 1.0))
	projectile_speed = float(base.get("projectile_speed", 400.0))
	see_shadow = base.get("see_shadow", false)
	can_pop_iron = base.get("can_pop_iron", false)
	full_track_range = base.get("full_track_range", false)
	
	# Apply path tier upgrades
	var paths = cat_data.get("paths", {})
	for p_key in paths.keys():
		var t_level = tiers.get(p_key, 0)
		var p_info = paths[p_key]
		var t_list: Array = p_info.get("tiers", [])
		for idx in range(mini(t_level, t_list.size())):
			var t_data: Dictionary = t_list[idx]
			if t_data.has("damage"):
				damage = int(t_data["damage"])
			if t_data.has("damage_type"):
				damage_type = SimConstants.damage_type_from_string(t_data["damage_type"])
			if t_data.has("pierce"):
				pierce = int(t_data["pierce"])
			if t_data.has("bonus_pierce"):
				pierce += int(t_data["bonus_pierce"])
			if t_data.has("range"):
				range_radius = float(t_data["range"])
			if t_data.has("cooldown"):
				cooldown = float(t_data["cooldown"])
			if t_data.has("see_shadow"):
				see_shadow = t_data["see_shadow"]
			if t_data.has("full_track_range"):
				full_track_range = t_data["full_track_range"]
			if t_data.has("can_hit_ink") and t_data["can_hit_ink"]:
				# Ink immunity bypassed
				pass
				
	# Reset specialized feat/upgrade bonuses
	bonus_vs_porcelain = 0
	bonus_vs_rats = 0
	crit_chance = 0.0
	extra_projectiles = 0
	burn_dps_bonus = 0.0
	burn_duration_bonus = 0.0
	freeze_duration_bonus = 0.0
	slow_duration_bonus = 0.0
	explosion_radius_bonus = 0.0
	shatter_damage_bonus = 0
	hex_duration_bonus = 0.0
	hex_dps_bonus = 0.0
	extra_round_kibble = 0
	mark_duration_bonus = 0.0
	burst_shot_interval = 5
	cloud_duration_bonus = 0.0
	corrosion_duration_bonus = 0.0
	brew_primary_speed_bonus = 0.0
	midas_ratio_bonus = 0.0
	midas_cap_bonus = 0

	# Apply Feat cards
	for f in selected_feats:
		if f.has("damage_add"):
			damage += int(f["damage_add"])
		if f.has("pierce_add"):
			pierce += int(f["pierce_add"])
		if f.has("range_mult"):
			range_radius *= (1.0 + float(f["range_mult"]))
		if f.has("range_add"):
			range_radius += float(f["range_add"])
		if f.has("speed_mult"):
			cooldown /= maxf(0.1, (1.0 + float(f["speed_mult"])))
		if f.has("grant_night_eye") and f["grant_night_eye"]:
			see_shadow = true
		if f.has("bonus_porcelain"):
			bonus_vs_porcelain += int(f["bonus_porcelain"])
		if f.has("bonus_rats"):
			bonus_vs_rats += int(f["bonus_rats"])
		if f.has("crit_chance"):
			crit_chance += float(f["crit_chance"])
		if f.has("extra_projectiles"):
			extra_projectiles += int(f["extra_projectiles"])
		if f.has("burn_dps_bonus"):
			burn_dps_bonus += float(f["burn_dps_bonus"])
		if f.has("burn_duration_bonus"):
			burn_duration_bonus += float(f["burn_duration_bonus"])
		if f.has("freeze_duration_bonus"):
			freeze_duration_bonus += float(f["freeze_duration_bonus"])
		if f.has("slow_duration_bonus"):
			slow_duration_bonus += float(f["slow_duration_bonus"])
		if f.has("explosion_radius_bonus"):
			explosion_radius_bonus += float(f["explosion_radius_bonus"])
		if f.has("shatter_damage_bonus"):
			shatter_damage_bonus += int(f["shatter_damage_bonus"])
		if f.has("hex_duration_bonus"):
			hex_duration_bonus += float(f["hex_duration_bonus"])
		if f.has("hex_dps_bonus"):
			hex_dps_bonus += float(f["hex_dps_bonus"])
		if f.has("extra_round_kibble"):
			extra_round_kibble += int(f["extra_round_kibble"])
		if f.has("mark_duration_bonus"):
			mark_duration_bonus += float(f["mark_duration_bonus"])
		if f.has("burst_interval"):
			burst_shot_interval = int(f["burst_interval"])
		if f.has("cloud_duration_bonus"):
			cloud_duration_bonus += float(f["cloud_duration_bonus"])
		if f.has("corrosion_duration_bonus"):
			corrosion_duration_bonus += float(f["corrosion_duration_bonus"])
		if f.has("brew_primary_speed_bonus"):
			brew_primary_speed_bonus += float(f["brew_primary_speed_bonus"])
		if f.has("midas_ratio_bonus"):
			midas_ratio_bonus += float(f["midas_ratio_bonus"])
		if f.has("midas_cap_bonus"):
			midas_cap_bonus += int(f["midas_cap_bonus"])

func tick_cooldown(delta: float) -> bool:
	attack_timer -= delta
	if attack_timer <= 0.0:
		attack_timer = get_effective_cooldown()
		shot_counter += 1
		return true
	return false

