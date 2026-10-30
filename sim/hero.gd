# Clowder: Alley Siege - Hero Cat Sim
class_name SimHero
extends RefCounted

const SimConstants = preload("res://sim/constants.gd")

const XP_TABLE: Array[int] = [
	0,     80,    200,   380,   620,
	920,   1300,  1750,  2300,  2950,
	3700,  4550,  5500,  6550,  7700,
	9000,  10400, 11900, 13500, 15200
]

var id: String = "mittens"
var hero_name: String = "Mittens"
var position: Vector2 = Vector2.ZERO
var place_cost: int = 600

var level: int = 1
var xp: float = 0.0
var damage_this_round: float = 0.0
var total_damage: float = 0.0

# Base stats
var base_damage: int = 1
var damage_type: int = SimConstants.DamageType.CLAW
var pierce: int = 3
var range_radius: float = 160.0
var cooldown: float = 0.8
var see_shadow: bool = false

# Current calculated stats
var current_damage: int = 1
var current_cooldown: float = 0.8
var current_range: float = 160.0

# Timers & cooldowns
var attack_timer: float = 0.0
var ability_1_cooldown_left: float = 0.0
var ability_2_cooldown_left: float = 0.0

# Hero move rules
var moves_used: int = 0
var move_cooldown_rounds: int = 0

var hero_data: Dictionary = {}

func setup(p_hero_data: Dictionary, pos: Vector2, start_level: int = 1) -> void:
	hero_data = p_hero_data
	id = hero_data.get("id", "mittens")
	hero_name = hero_data.get("name", "Mittens")
	place_cost = int(hero_data.get("place_cost", 600))
	position = pos
	level = start_level
	xp = XP_TABLE[mini(start_level - 1, XP_TABLE.size() - 1)]
	
	var base = hero_data.get("base", {})
	base_damage = int(base.get("damage", 1))
	damage_type = SimConstants.damage_type_from_string(base.get("damage_type", "Claw"))
	pierce = int(base.get("pierce", 3))
	range_radius = float(base.get("range", 160.0))
	cooldown = float(base.get("cooldown", 0.8))
	see_shadow = base.get("see_shadow", false)
	
	_recalculate_stats()

func add_round_xp(round_num: int, xp_bonus_mult: float = 1.0) -> int:
	var round_xp = (20.0 + 3.0 * float(round_num) + 0.02 * damage_this_round) * xp_bonus_mult
	xp += round_xp
	damage_this_round = 0.0
	
	var old_lvl = level
	while level < 20 and xp >= XP_TABLE[level]:
		level += 1
		
	if level > old_lvl:
		_recalculate_stats()
	return level

func _recalculate_stats() -> void:
	var dmg_scale = 1.0 + (level - 1) * 0.03
	var spd_scale = 1.0 + (level - 1) * 0.015
	var even_levels = floori(float(level) / 2.0)
	var range_bonus = even_levels * 4.0
	
	current_damage = int(round(float(base_damage) * dmg_scale))
	current_cooldown = cooldown / spd_scale
	current_range = range_radius + range_bonus
	
	# Kit specific level milestones
	if id == "mittens":
		if level >= 4:
			see_shadow = true
		if level >= 6:
			damage_type = SimConstants.DamageType.BITE
		if level >= 7:
			current_cooldown /= 1.20
	elif id == "duchess":
		if level >= 8:
			see_shadow = false
			damage_type = SimConstants.DamageType.VOID

func tick(delta: float) -> void:
	if ability_1_cooldown_left > 0.0:
		ability_1_cooldown_left = maxf(0.0, ability_1_cooldown_left - delta)
	if ability_2_cooldown_left > 0.0:
		ability_2_cooldown_left = maxf(0.0, ability_2_cooldown_left - delta)

func can_use_ability(slot: int) -> bool:
	if slot == 1:
		return level >= 3 and ability_1_cooldown_left <= 0.0
	elif slot == 2:
		return level >= 10 and ability_2_cooldown_left <= 0.0
	return false

func trigger_ability(slot: int, cd_reduction_ratio: float = 0.0) -> Dictionary:
	var result = {"triggered": false, "name": ""}
	if not can_use_ability(slot):
		return result
		
	var abilities = hero_data.get("active_abilities", {})
	var a_key = "ability_1" if slot == 1 else "ability_2"
	var adata: Dictionary = abilities.get(a_key, {})
	
	var base_cd = float(adata.get("cooldown", 40.0))
	var final_cd = base_cd * (1.0 - cd_reduction_ratio)
	
	if slot == 1:
		ability_1_cooldown_left = final_cd
	else:
		ability_2_cooldown_left = final_cd
		
	result["triggered"] = true
	result["name"] = adata.get("name", "")
	result["data"] = adata
	return result

