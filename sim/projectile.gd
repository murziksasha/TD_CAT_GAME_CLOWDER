# Clowder: Alley Siege - Projectile / Attack Sim
class_name SimProjectile
extends RefCounted

const SimConstants = preload("res://sim/constants.gd")

var id: int = 0
var source_cat_id: int = 0
var position: Vector2 = Vector2.ZERO
var target_unit_id: int = -1
var target_position: Vector2 = Vector2.ZERO

var damage: int = 1
var damage_type: int = SimConstants.DamageType.CLAW
var pierce_left: int = 1
var speed: float = 400.0
var radius: float = 0.0 # for explosions or hitboxes
var is_explosion: bool = false
var is_seeking: bool = false
var turn_rate: float = 6.0
var travel_time_left: float = 0.0

var bonus_porcelain: int = 0
var bonus_rats: int = 0
var is_crit: bool = false
var mark_on_hit: int = 0
var mark_duration: float = 0.0
var freeze_duration: float = 0.0
var burn_dps: float = 0.0
var burn_duration: float = 0.0

var already_hit_unit_ids: Dictionary = {} # Set of unit_ids hit
var is_active: bool = true

func setup_linear(
	p_id: int,
	cat_id: int,
	start_pos: Vector2,
	target_pos: Vector2,
	p_damage: int,
	p_damage_type: int,
	p_pierce: int,
	p_speed: float,
	p_seeking: bool = false
) -> void:
	id = p_id
	source_cat_id = cat_id
	position = start_pos
	target_position = target_pos
	damage = p_damage
	damage_type = p_damage_type
	pierce_left = p_pierce
	speed = p_speed
	is_seeking = p_seeking
	is_active = true

func setup_lob(
	p_id: int,
	cat_id: int,
	target_pos: Vector2,
	p_damage: int,
	p_damage_type: int,
	p_pierce: int,
	p_radius: float,
	p_travel_time: float
) -> void:
	id = p_id
	source_cat_id = cat_id
	target_position = target_pos
	position = target_pos
	damage = p_damage
	damage_type = p_damage_type
	pierce_left = p_pierce
	radius = p_radius
	travel_time_left = p_travel_time
	is_explosion = true
	is_active = true

func tick(delta: float, target_pos: Vector2 = Vector2.ZERO) -> bool:
	if not is_active:
		return false
		
	if is_explosion:
		travel_time_left -= delta
		if travel_time_left <= 0.0:
			# Explosion detonates
			return true
		return false
	else:
		if is_seeking and target_pos != Vector2.ZERO:
			target_position = target_pos
		var dir = (target_position - position).normalized()
		position += dir * speed * delta
		if position.distance_to(target_position) < 10.0 and not is_seeking:
			# Reached end point
			is_active = false
		return false

