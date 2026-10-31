# Clowder: Alley Siege - Cat Tower Sim
class_name SimTower
extends RefCounted

const SimConstants = preload("res://sim/constants.gd")
const SimFeats = preload("res://sim/feats.gd")

var instance_id: int = 0
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
var see_shadow: bool = false
var can_pop_iron: bool = false
var full_track_range: bool = false

# Internal cooldown / attack tracking
var attack_timer: float = 0.0
var shot_counter: int = 0

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
	var has_path_above_2 = false
	for p in ["path_a", "path_b", "path_c"]:
		if tiers[p] > 0:
			upgraded_paths += 1
		if tiers[p] >= 3:
			has_path_above_2 = true
			
	if tiers[path_key] == 0 and upgraded_paths >= 2:
		return false
		
	if has_path_above_2 and current_tier >= 2:
		# If another path is >= 3 and this one is already 2, cannot go to 3
		return false
		
	return true

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
				
	# Apply Feat cards
	for f in selected_feats:
		if f.has("damage_add"):
			damage += int(f["damage_add"])
		if f.has("pierce_add"):
			pierce += int(f["pierce_add"])
		if f.has("range_mult"):
			range_radius *= (1.0 + float(f["range_mult"]))
		if f.has("speed_mult"):
			cooldown /= maxf(0.1, (1.0 + float(f["speed_mult"])))
		if f.has("grant_night_eye") and f["grant_night_eye"]:
			see_shadow = true

func tick_cooldown(delta: float) -> bool:
	attack_timer -= delta
	if attack_timer <= 0.0:
		attack_timer = cooldown
		shot_counter += 1
		return true
	return false

