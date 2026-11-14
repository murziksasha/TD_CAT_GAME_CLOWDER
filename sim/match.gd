# Clowder: Alley Siege - Headless Match Simulator
class_name SimMatch
extends RefCounted

const SimConstants = preload("res://sim/constants.gd")
const SimEconomy = preload("res://sim/economy.gd")
const SimReplay = preload("res://sim/replay.gd")
const SimTower = preload("res://sim/tower.gd")
const SimHero = preload("res://sim/hero.gd")
const SimUnit = preload("res://sim/unit.gd")
const SimProjectile = preload("res://sim/projectile.gd")

var tick_counter: int = 0
var mode: int = SimConstants.GameMode.SUNNY
var map_id: String = "sunny_gutter"
var map_revision: int = 1
var path_length: float = 1200.0
var paths: Array[Dictionary] = []
var sight_blockers: Array[Rect2] = []
var map_data: Dictionary = {}
var placement_zones: Dictionary = {}
var removable_obstacles: Array[Dictionary] = []
var cleared_obstacle_ids: Dictionary = {}

var lives: int = 200
var max_lives: int = 200
var current_round: int = 0
var max_rounds: int = 40
var match_won: bool = false
var match_lost: bool = false

var economy: SimEconomy
var replay: SimReplay
var random: RandomNumberGenerator

var towers: Array[SimTower] = []
var hero: SimHero = null
var units: Array[SimUnit] = []
var projectiles: Array[SimProjectile] = []

# Presentation-only output. The simulator writes events but never consumes them.
var presentation_log: Array[Dictionary] = []

var pending_spawns: Array[Dictionary] = [] # {"time": 0.5, "unit_config": {...}}
var round_in_progress: bool = false
var unit_id_counter: int = 0
var proj_id_counter: int = 0
var marlow_sonar_elapsed: Dictionary = {}

# Active battle hazard zones and active buffs
var ground_zones: Array[Dictionary] = []
var leak_history: Array[Dictionary] = []
var blocked_immunity_counts: Dictionary = {}
var skim_bonus_active: bool = false
var skim_rounds_left: int = 0
var pebble_leak_reduction_used_this_round: bool = false
var miso_bell_timer: float = 0.0
var miso_bell_speed: float = 0.0
var miso_bell_damage: int = 0
var miso_shadow_reveal_timer: float = 0.0
var peak_kibble: int = 0
# Total authoritative HP removed by every damage source. Testing and statistics
# consume this counter instead of presentation events or nominal attack damage.
var total_hp_removed: int = 0
var expansion_effects: Dictionary = {}
var tricks_data: Dictionary = {}
var trick_cooldowns: Dictionary = {}
var lantern_reveal_time: float = 0.0
var catnip_frenzy_time: float = 0.0

# Loaded data repositories
var mice_data: Dictionary = {}
var rats_data: Dictionary = {}
var cat_blueprints: Dictionary = {}
var hero_blueprints: Dictionary = {}
var round_data: Dictionary = {}

func _note_presentation(event_type: String, payload: Dictionary = {}) -> void:
	var event := {"type": event_type, "tick": tick_counter}
	event.merge(payload, true)
	presentation_log.append(event)
	if presentation_log.size() > 256:
		presentation_log.remove_at(0)

func drain_presentation_log() -> Array[Dictionary]:
	var drained := presentation_log.duplicate(true)
	presentation_log.clear()
	return drained

func setup(
	p_mode: int,
	p_seed: int,
	p_mice_data: Dictionary,
	p_rats_data: Dictionary,
	p_cat_blueprints: Dictionary,
	p_hero_blueprints: Dictionary,
	p_round_data: Dictionary,
	start_kibble_bonus: int = 0,
	p_map_data: Dictionary = {}
) -> void:
	mode = p_mode
	mice_data = p_mice_data
	rats_data = p_rats_data
	cat_blueprints = p_cat_blueprints
	hero_blueprints = p_hero_blueprints
	round_data = p_round_data
	
	if not p_map_data.is_empty():
		load_map_data(p_map_data)
	else:
		_init_default_sunny_path()
	
	random = RandomNumberGenerator.new()
	random.seed = p_seed
	
	replay = SimReplay.new()
	replay.setup(p_seed, map_id, mode, map_revision)
	
	economy = SimEconomy.new()
	economy.setup(mode, start_kibble_bonus)
	
	match mode:
		SimConstants.GameMode.SUNNY:
			lives = 200
			max_rounds = 40
		SimConstants.GameMode.ALLEY:
			lives = 150
			max_rounds = 60
		SimConstants.GameMode.NIGHT:
			lives = 100
			max_rounds = 80
		SimConstants.GameMode.LAST_WHISKER, SimConstants.GameMode.BARE_PAW:
			lives = 1
			max_rounds = 100
	max_lives = lives
	current_round = 0

func load_tricks_data(p_tricks_data: Dictionary) -> void:
	tricks_data = p_tricks_data

func configure_expansion_effects(effects: Dictionary) -> void:
	expansion_effects = effects.duplicate(true)
	economy.ruleset_pop_income_multiplier = 1.0 + float(expansion_effects.get("pop_kibble_percent", 0.0)) / 100.0

func _init_default_sunny_path() -> void:
	map_id = "sunny_gutter"
	map_revision = 1
	path_length = 1200.0
	paths = [
		{
			"id": "main_loop",
			"points": [
				Vector2(40.0, 100.0),
				Vector2(640.0, 100.0),
				Vector2(640.0, 400.0),
				Vector2(340.0, 400.0)
			],
			"cum_lengths": [0.0, 600.0, 900.0, 1200.0],
			"length": 1200.0
		}
	]
	sight_blockers.clear()
	removable_obstacles.clear()
	cleared_obstacle_ids.clear()
	placement_zones = {"land": [{"x": 0.0, "y": 0.0, "width": 1280.0, "height": 720.0}], "water": [], "perches": []}

func load_map_data(p_map_data: Dictionary) -> void:
	map_data = p_map_data
	map_id = p_map_data.get("id", "sunny_gutter")
	map_revision = int(p_map_data.get("map_revision", 1))
	paths.clear()
	sight_blockers.clear()
	removable_obstacles.clear()
	cleared_obstacle_ids.clear()
	placement_zones = p_map_data.get("placement_zones", {}).duplicate(true)
	for raw_obstacle in p_map_data.get("obstacles", []):
		if raw_obstacle is Dictionary and not str(raw_obstacle.get("id", "")).is_empty():
			removable_obstacles.append(raw_obstacle.duplicate(true))
	
	var raw_paths: Array = p_map_data.get("paths", [])
	for i in range(raw_paths.size()):
		var rp: Dictionary = raw_paths[i]
		var raw_pts: Array = rp.get("points", [])
		var pts: Array[Vector2] = []
		for pt in raw_pts:
			if pt is Vector2:
				pts.append(pt)
			elif pt is Dictionary:
				pts.append(Vector2(float(pt.get("x", 0.0)), float(pt.get("y", 0.0))))
				
		var cum_lengths: Array[float] = [0.0]
		for j in range(pts.size() - 1):
			var seg: float = pts[j].distance_to(pts[j + 1])
			cum_lengths.append(cum_lengths[-1] + seg)
			
		# Movement, leaks, and timing use the measured polyline, never a stale label.
		var total_len: float = cum_lengths[-1]
		paths.append({
			"id": rp.get("id", "path_%d" % i),
			"points": pts,
			"cum_lengths": cum_lengths,
			"length": total_len
		})
		
	if not paths.is_empty():
		path_length = paths[0].length
	else:
		path_length = 1200.0
		
	var raw_blockers: Array = p_map_data.get("sight_blockers", [])
	for sb in raw_blockers:
		if sb is Rect2:
			sight_blockers.append(sb)
		elif sb is Dictionary:
			var x = float(sb.get("x", 0.0))
			var y = float(sb.get("y", 0.0))
			var w = float(sb.get("width", float(sb.get("w", 40.0))))
			var h = float(sb.get("height", float(sb.get("h", 40.0))))
			sight_blockers.append(Rect2(x, y, w, h))

func get_path_length(path_index: int = 0) -> float:
	if path_index >= 0 and path_index < paths.size():
		return paths[path_index].length
	return path_length

func get_point_on_path(s: float, path_index: int = 0) -> Vector2:
	if paths.is_empty():
		var clamped_s = clampf(s, 0.0, path_length)
		if clamped_s <= 600.0:
			return Vector2(40.0 + clamped_s, 100.0)
		elif clamped_s <= 900.0:
			return Vector2(640.0, 100.0 + (clamped_s - 600.0))
		else:
			return Vector2(640.0 - (clamped_s - 900.0), 400.0)
			
	var p_idx = clamp(path_index, 0, paths.size() - 1)
	var p_info: Dictionary = paths[p_idx]
	var p_len: float = p_info.length
	var clamped_s: float = clampf(s, 0.0, p_len)
	var pts: Array = p_info.points
	var cum: Array = p_info.cum_lengths
	
	if pts.size() == 0:
		return Vector2.ZERO
	if pts.size() == 1:
		return pts[0]
		
	for i in range(pts.size() - 1):
		var s_start: float = cum[i]
		var s_end: float = cum[i + 1]
		if clamped_s <= s_end or i == pts.size() - 2:
			var seg_len = s_end - s_start
			if seg_len <= 0.0001:
				return pts[i]
			var t = (clamped_s - s_start) / seg_len
			return pts[i].lerp(pts[i + 1], t)
			
	return pts[-1]

func get_active_paths_for_round(r: int) -> Array[int]:
	var sched: Dictionary = map_data.get("verbs", {}).get("schedule", {})
	var r_paths: Dictionary = sched.get("round_paths", {})
	var r_str = str(r)
	if r_paths.has(r_str):
		var res: Array[int] = []
		for p in r_paths[r_str]:
			res.append(int(p))
		return res
	var def_paths: Array = sched.get("default_paths", [])
	if not def_paths.is_empty():
		var res: Array[int] = []
		for p in def_paths:
			res.append(int(p))
		return res
	if not paths.is_empty():
		var all_indices: Array[int] = []
		for i in range(paths.size()):
			all_indices.append(i)
		return all_indices
	return [0]

func get_upcoming_schedule(from_round: int, count: int = 3) -> Array[Dictionary]:
	var preview: Array[Dictionary] = []
	for offset in range(count):
		var target_r = from_round + offset
		preview.append({
			"round": target_r,
			"active_paths": get_active_paths_for_round(target_r)
		})
	return preview

func _line_intersects_rect(p1: Vector2, p2: Vector2, rect: Rect2) -> bool:
	if rect.has_point(p1) or rect.has_point(p2):
		return true
	var tl = rect.position
	var tr = rect.position + Vector2(rect.size.x, 0)
	var bl = rect.position + Vector2(0, rect.size.y)
	var br = rect.position + rect.size
	return (
		_segments_intersect(p1, p2, tl, tr) or
		_segments_intersect(p1, p2, tr, br) or
		_segments_intersect(p1, p2, br, bl) or
		_segments_intersect(p1, p2, bl, tl)
	)

func _segments_intersect(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> bool:
	var denom = (b.x - a.x) * (d.y - c.y) - (b.y - a.y) * (d.x - c.x)
	if absf(denom) < 0.0001:
		return false
	var t = ((c.x - a.x) * (d.y - c.y) - (c.y - a.y) * (d.x - c.x)) / denom
	var u = -((b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)) / denom
	return (t >= 0.0 and t <= 1.0 and u >= 0.0 and u <= 1.0)

func has_line_of_sight(from_pos: Vector2, to_pos: Vector2) -> bool:
	for blocker in sight_blockers:
		if _line_intersects_rect(from_pos, to_pos, blocker):
			return false
	return true

func place_tower(cat_id: String, pos: Vector2, owner_id: int = 1) -> SimTower:
	var placement := can_place_tower_at(cat_id, pos)
	if not placement.get("valid", false):
		return null
	var cdata: Dictionary = cat_blueprints.get(cat_id, {})
	var price = int(placement.get("price", cdata.get("cost", 200)))
	
	if not economy.spend(price):
		return null
		
	unit_id_counter += 1
	var tower = SimTower.new()
	tower.setup(unit_id_counter, cdata, pos, price)
	tower.ruleset_range_mult = float(expansion_effects.get("cat_range_percent", 0.0)) / 100.0
	tower.ruleset_speed_mult = float(expansion_effects.get("attack_speed_percent", 0.0)) / 100.0
	tower.ruleset_projectile_speed_mult = float(expansion_effects.get("projectile_speed_percent", 0.0)) / 100.0
	tower.footprint_radius *= 1.0 + float(expansion_effects.get("footprint_percent", 0.0)) / 100.0
	tower.owner_id = owner_id
	towers.append(tower)
	_update_aura_buffs()
	_note_presentation("place", {"id": tower.instance_id, "cat": cat_id, "x": pos.x, "y": pos.y, "owner_id": owner_id})
	
	replay.log_action(tick_counter, "place_tower", {"cat_id": cat_id, "pos": [pos.x, pos.y], "owner_id": owner_id})
	return tower

func place_hero(hero_id: String, pos: Vector2) -> SimHero:
	var placement := can_place_hero_at(hero_id, pos)
	if not placement.get("valid", false):
		return null
	if hero != null:
		return null
	var hdata: Dictionary = hero_blueprints.get(hero_id, {})
	var cost = int(hdata.get("place_cost", 600))
	var price = economy.calculate_price(cost)
	
	if not economy.spend(price):
		return null
		
	hero = SimHero.new()
	hero.setup(hdata, pos, 1)
	_update_aura_buffs()
	_note_presentation("place", {"id": -1, "cat": hero_id, "hero": true, "x": pos.x, "y": pos.y})
	replay.log_action(tick_counter, "place_hero", {"hero_id": hero_id, "pos": [pos.x, pos.y]})
	return hero

func can_upgrade_tower(tower: SimTower, path_key: String) -> Dictionary:
	var reason = tower.get_crosspath_block_reason(path_key)
	if reason != "":
		return {"allowed": false, "reason": reason}
	var next_tier = tower.tiers.get(path_key, 0) + 1
	if next_tier == 5:
		for other in towers:
			if other != tower and other.cat_id == tower.cat_id and other.tiers.get(path_key, 0) >= 5:
				return {"allowed": false, "reason": "UNIQUE_T5_EXISTS"}
	var paths = tower.cat_data.get("paths", {})
	var p_info = paths.get(path_key, {})
	var t_list: Array = p_info.get("tiers", [])
	if next_tier - 1 >= t_list.size():
		return {"allowed": false, "reason": "MAX_TIER"}
	var base_cost = int(t_list[next_tier - 1].get("cost", 100))
	var discounts = get_tower_discounts(tower)
	var price = economy.calculate_price(base_cost, discounts)
	if not economy.can_afford(price):
		return {"allowed": false, "reason": "NO_KIBBLE", "price": price}
	return {"allowed": true, "reason": "OK", "price": price}

func upgrade_tower(tower: SimTower, path_key: String) -> bool:
	var check = can_upgrade_tower(tower, path_key)
	if not check.get("allowed", false):
		return false
	var price = int(check.get("price", 0))
	if not economy.spend(price):
		return false
		
	tower.apply_upgrade(path_key, price)
	_update_aura_buffs()
	_note_presentation("upgrade", {"id": tower.instance_id, "path": path_key, "tier": tower.tiers.get(path_key, 0)})
	replay.log_action(tick_counter, "upgrade_tower", {"tower_id": tower.instance_id, "path": path_key})
	return true

func sell_tower(tower: SimTower) -> int:
	if not economy.allow_selling:
		return 0
	var refund = economy.refund_sell(tower.total_spent)
	_remove_tower_side_effects(tower)
	towers.erase(tower)
	_update_aura_buffs()
	replay.log_action(tick_counter, "sell_tower", {"tower_id": tower.instance_id})
	return refund

func lift_tower_tide(tower: SimTower) -> int:
	# Fairness Gate 6 / Spec 12: Lift refund is 100% of total spent
	var refund = tower.total_spent
	economy.kibble += refund
	_remove_tower_side_effects(tower)
	towers.erase(tower)
	_update_aura_buffs()
	_note_presentation("tide_lift", {"id": tower.instance_id, "refund": refund})
	replay.log_action(tick_counter, "tide_lift", {"tower_id": tower.instance_id, "refund": refund})
	return refund

func _remove_tower_side_effects(tower: SimTower) -> void:
	var kept_zones: Array[Dictionary] = []
	for zone in ground_zones:
		if int(zone.get("source_tower_id", -1)) != tower.instance_id:
			kept_zones.append(zone)
	ground_zones = kept_zones
	for other in towers:
		if other.brew_target_id == tower.instance_id:
			other.brew_target_id = -1

func can_assign_brew(bub: SimTower, target: SimTower) -> Dictionary:
	if round_in_progress:
		return {"allowed": false, "reason": "BETWEEN_ROUNDS_ONLY"}
	if bub == null or not towers.has(bub) or bub.cat_id != "bub":
		return {"allowed": false, "reason": "INVALID_BUB"}
	if int(bub.tiers.get("path_b", 0)) < 3:
		return {"allowed": false, "reason": "BREW_NOT_UNLOCKED"}
	if target == null or not towers.has(target) or target == bub:
		return {"allowed": false, "reason": "INVALID_TARGET"}
	if bub.position.distance_to(target.position) > bub.get_effective_range():
		return {"allowed": false, "reason": "OUT_OF_RANGE"}
	return {"allowed": true, "reason": "OK"}

func assign_brew(bub: SimTower, target: SimTower) -> bool:
	var check := can_assign_brew(bub, target)
	if not bool(check.get("allowed", false)):
		return false
	bub.brew_target_id = target.instance_id
	_update_aura_buffs()
	_note_presentation("brew", {"id": bub.instance_id, "target": target.instance_id, "x": target.position.x, "y": target.position.y})
	replay.log_action(tick_counter, "assign_brew", {"tower_id": bub.instance_id, "target_id": target.instance_id})
	return true

func get_tower_discounts(tower: SimTower) -> Array[float]:
	var discounts: Array[float] = []
	for other in towers:
		if other != tower and other.cat_id == "miso":
			var rad = _get_miso_aura_radius(other)
			if other.position.distance_to(tower.position) <= rad:
				var disc = _get_miso_discount(other)
				if disc > 0.0:
					discounts.append(disc)
		elif other != tower and other.cat_id == "goldie":
			if other.tiers.get("path_c", 0) >= 5:
				discounts.append(0.10)
			elif other.tiers.get("path_c", 0) >= 3 and other.position.distance_to(tower.position) <= 120.0:
				discounts.append(0.05)
	return discounts

func get_placement_discounts(pos: Vector2) -> Array[float]:
	var discounts: Array[float] = []
	for other in towers:
		if other.cat_id == "miso":
			var rad = _get_miso_aura_radius(other)
			if other.position.distance_to(pos) <= rad:
				var disc = _get_miso_discount(other)
				if disc > 0.0:
					discounts.append(disc)
		elif other.cat_id == "goldie":
			if other.tiers.get("path_c", 0) >= 5:
				discounts.append(0.10)
			elif other.tiers.get("path_c", 0) >= 3 and other.position.distance_to(pos) <= 120.0:
				discounts.append(0.05)
	return discounts

func _get_miso_aura_radius(miso_tower: SimTower) -> float:
	var r = 110.0
	if miso_tower.tiers.get("path_b", 0) >= 5:
		r = 260.0
	elif miso_tower.tiers.get("path_a", 0) >= 5:
		r = 200.0
	elif miso_tower.tiers.get("path_a", 0) >= 4:
		r = 160.0
	elif miso_tower.tiers.get("path_b", 0) >= 2:
		r = 150.0
	return r * (1.0 + miso_tower.aura_range_mult)

func _get_miso_discount(miso_tower: SimTower) -> float:
	var c = miso_tower.tiers.get("path_c", 0)
	if c >= 3:
		return 0.15
	elif c >= 2:
		return 0.10
	elif c >= 1:
		return 0.05
	return 0.0

func _cat_tier_value(tower: SimTower, key: String, fallback: float = 0.0) -> float:
	var value := fallback
	var paths_data: Dictionary = tower.cat_data.get("paths", {})
	for path_key in paths_data:
		var tier_rows: Array = paths_data[path_key].get("tiers", [])
		for tier_index in range(mini(int(tower.tiers.get(path_key, 0)), tier_rows.size())):
			if tier_rows[tier_index].has(key):
				value = float(tier_rows[tier_index][key])
	return value

func _update_aura_buffs() -> void:
	for tower in towers:
		tower.clear_brew_buff()
	for t in towers:
		var best_dmg = 0
		var best_rng = 0.0
		var best_spd = 0.0
		var best_pierce = 0
		var grant_night = false
		var best_crit = 0.0
		var sources: Array[int] = []
		
		for m in towers:
			if m != t and m.cat_id == "miso":
				var rad = _get_miso_aura_radius(m)
				if m.position.distance_to(t.position) <= rad:
					sources.append(m.instance_id)
					var rng_b = 0.10
					if m.tiers.get("path_a", 0) >= 5:
						rng_b = 0.20
					elif m.tiers.get("path_a", 0) >= 2:
						rng_b = 0.15
					best_rng = maxf(best_rng, rng_b)
					
					var spd_b = 0.0
					if m.tiers.get("path_a", 0) >= 5:
						spd_b = 0.25
					elif m.tiers.get("path_a", 0) >= 3:
						spd_b = 0.18
					elif m.tiers.get("path_a", 0) >= 1:
						spd_b = 0.10
					if miso_bell_timer > 0.0:
						spd_b += miso_bell_speed
					best_spd = maxf(best_spd, spd_b)
					
					var p_b = 0
					if m.tiers.get("path_b", 0) >= 5:
						p_b = 2
					elif m.tiers.get("path_b", 0) >= 3:
						p_b = 1
					best_pierce = maxi(best_pierce, p_b)
					
					if m.tiers.get("path_b", 0) >= 1:
						grant_night = true
						
					if m.tiers.get("path_a", 0) >= 4 and t.category == "Alley":
						best_dmg = maxi(best_dmg, 1)
					if miso_bell_timer > 0.0 and miso_bell_damage > 0:
						if t.category == "Alley" or t.category == "Hunt":
							best_dmg += miso_bell_damage
							
					if m.tiers.get("path_a", 0) >= 5 and t.category == "Hunt":
						best_crit = maxf(best_crit, 0.10)
						
		if hero != null and hero.position.distance_to(t.position) <= hero.get_effective_range():
			if hero.id == "mittens" and hero.level >= 7:
				if t.category == "Alley":
					best_spd += 0.05
			elif hero.id == "duchess" and hero.level >= 7:
				if t.damage_type == SimConstants.DamageType.BLAST or t.cat_id == "biscuit":
					t.explosion_radius_bonus = 15.0
			elif hero.id == "baron" and hero.level >= 7:
				if t.damage_type == SimConstants.DamageType.BLAST or t.cat_id == "biscuit":
					best_dmg += 1
					
		if catnip_frenzy_time > 0.0:
			best_spd += 0.50
			
		t.apply_aura_buffs(best_dmg, best_rng, best_spd, best_pierce, grant_night, best_crit, sources)
		
	for m in towers:
		if m.cat_id == "miso":
			var rad = _get_miso_aura_radius(m)
			var count = 0
			for t in towers:
				if t != m and m.position.distance_to(t.position) <= rad:
					count += 1
			m.buffed_cats_count = count

	# Bub Brew is persistent while its source and selected target remain on-map.
	# Multiple sources never add; SimTower keeps the strongest value per stat.
	for bub in towers:
		if bub.cat_id != "bub" or int(bub.tiers.get("path_b", 0)) < 3:
			continue
		var target := _get_tower_by_id(bub.brew_target_id)
		if target == null or target == bub:
			bub.brew_target_id = -1
			continue
		var speed := _cat_tier_value(bub, "brew_speed_ratio") + bub.brew_primary_speed_bonus
		var range_mult := _cat_tier_value(bub, "brew_range_ratio")
		var damage_bonus := int(_cat_tier_value(bub, "brew_damage_bonus"))
		var pierce_bonus := int(_cat_tier_value(bub, "brew_pierce_bonus"))
		target.apply_brew_buff(damage_bonus, range_mult, speed, pierce_bonus, bub.instance_id)
		var splash_radius := _cat_tier_value(bub, "brew_splash_radius")
		if splash_radius > 0.0:
			for ally in towers:
				if ally == bub or ally == target or ally.position.distance_to(target.position) > splash_radius:
					continue
				ally.apply_brew_buff(
					0,
					_cat_tier_value(bub, "brew_splash_range_ratio"),
					_cat_tier_value(bub, "brew_splash_speed_ratio"),
					int(_cat_tier_value(bub, "brew_splash_pierce_bonus")),
					bub.instance_id
				)
			
	if hero != null:
		var best_rng = 0.0
		var best_spd = 0.0
		var best_dmg = 0
		for m in towers:
			if m.cat_id == "miso":
				var rad = _get_miso_aura_radius(m)
				if m.position.distance_to(hero.position) <= rad:
					var rng_b = 0.10
					if m.tiers.get("path_a", 0) >= 5:
						rng_b = 0.20
					elif m.tiers.get("path_a", 0) >= 2:
						rng_b = 0.15
					best_rng = maxf(best_rng, rng_b)
					
					var spd_b = 0.0
					if m.tiers.get("path_a", 0) >= 5:
						spd_b = 0.25
					elif m.tiers.get("path_a", 0) >= 3:
						spd_b = 0.18
					elif m.tiers.get("path_a", 0) >= 1:
						spd_b = 0.10
					if miso_bell_timer > 0.0:
						spd_b += miso_bell_speed
					best_spd = maxf(best_spd, spd_b)
					
		hero.aura_range_mult = best_rng * 0.5
		hero.aura_speed_mult = best_spd * 0.5
		hero.aura_damage_bonus = int(floor(best_dmg * 0.5))

func start_next_round() -> bool:
	if round_in_progress or current_round >= max_rounds:
		return false
		
	current_round += 1
	round_in_progress = true
	pending_spawns.clear()
	for tower in towers:
		tower.midas_kibble_this_round = 0
		tower.midas_fraction = 0.0
	
	var rkey = str(current_round)
	var rgroups: Array = round_data.get("rounds", {}).get(rkey, [])
	var map_modifier := _round_map_modifier(current_round)
	
	var cur_delay = 0.0
	var active_paths = get_active_paths_for_round(current_round)
	var spawn_seq_idx = 0
	var group_index := 0
	for grp in rgroups:
		group_index += 1
		var configured_group: Dictionary = grp.duplicate(true)
		if not configured_group.has("rat"):
			if map_modifier.has("force_coat"):
				configured_group["coat"] = map_modifier["force_coat"]
			if map_modifier.get("shadow", false):
				configured_group["shadow"] = true
			var ink_interval := int(expansion_effects.get("ink_interval_rounds", 0))
			if ink_interval > 0 and current_round % ink_interval == 0:
				configured_group["coat"] = "ink"
		var shadow_n := int(expansion_effects.get("shadow_every_nth_group", 0))
		if shadow_n > 0 and group_index % shadow_n == 0:
			configured_group["shadow"] = true
		var plated_n := int(expansion_effects.get("plated_every_nth_group", 0))
		if plated_n > 0 and group_index % plated_n == 0:
			configured_group["plated"] = true
		var count = int(configured_group.get("count", 1))
		var spacing = float(configured_group.get("spacing", 0.5)) * (1.0 + float(expansion_effects.get("round_spacing_percent", 0.0)) / 100.0)
		for _i in range(count):
			var spawn_item = configured_group.duplicate()
			spawn_item.erase("count")
			spawn_item.erase("spacing")
			if not spawn_item.has("path_index"):
				if not active_paths.is_empty():
					spawn_item["path_index"] = active_paths[spawn_seq_idx % active_paths.size()]
				else:
					spawn_item["path_index"] = 0
			pending_spawns.append({
				"delay": cur_delay,
				"config": spawn_item
			})
			cur_delay += spacing
			spawn_seq_idx += 1
			
	replay.log_action(tick_counter, "start_round", {"round": current_round})
	return true

func _round_map_modifier(round_number: int) -> Dictionary:
	var modifiers: Dictionary = map_data.get("verbs", {}).get("round_modifiers", {})
	var result: Dictionary = {}
	for threshold_key in modifiers:
		if int(threshold_key) <= round_number and modifiers[threshold_key] is Dictionary:
			result.merge(modifiers[threshold_key], true)
	return result

func spawn_unit(config: Dictionary, path_s: float = 0.0) -> SimUnit:
	unit_id_counter += 1
	var u = SimUnit.new()
	var is_super = (current_round >= 81)
	
	if config.has("rat"):
		var r_type = config.get("rat", "burrow")
		var plated = config.get("plated", false)
		var sunny_red = config.get("sunny_reduced_hp", false) and (mode == SimConstants.GameMode.SUNNY)
		u.setup_rat(unit_id_counter, r_type, rats_data, mice_data, plated, sunny_red, is_super)
	else:
		var coat = config.get("coat", "rust")
		var shadow = config.get("shadow", false)
		var gnaw = config.get("gnaw", false)
		var plated = config.get("plated", false)
		u.setup_mouse(unit_id_counter, coat, mice_data, shadow, gnaw, plated, is_super)
	if not u.is_rat:
		u.base_speed *= 1.0 + float(expansion_effects.get("mouse_speed_percent", 0.0)) / 100.0
	else:
		var rat_hp_mult := 1.0 + float(expansion_effects.get("rat_body_hp_percent", 0.0)) / 100.0
		u.body_hp = maxi(1, int(round(float(u.body_hp) * rat_hp_mult)))
		u.max_body_hp = u.body_hp
		u.layer_hp = u.body_hp
		u.max_layer_hp = u.body_hp
		
	u.path_index = int(config.get("path_index", 0))
	if u.path_index >= 0 and u.path_index < paths.size():
		u.path_id = paths[u.path_index].id
	else:
		u.path_id = config.get("path_id", "main_loop")
	u.s = path_s
	units.append(u)
	if u.is_rat:
		_note_presentation("rat_enter", {"id": u.id, "rat": u.unit_type, "s": u.s, "path_index": u.path_index})
	return u

func tick() -> void:
	if match_won or match_lost:
		return
		
	tick_counter += 1
	var dt = SimConstants.TICK_DELTA
	peak_kibble = maxi(peak_kibble, economy.kibble)
	
	# Tick miso bell timer
	if miso_bell_timer > 0.0:
		miso_bell_timer = maxf(0.0, miso_bell_timer - dt)
		if miso_bell_timer <= 0.0:
			_update_aura_buffs()

	# Tick active combat trick durations
	if lantern_reveal_time > 0.0:
		lantern_reveal_time = maxf(0.0, lantern_reveal_time - dt)
	if catnip_frenzy_time > 0.0:
		catnip_frenzy_time = maxf(0.0, catnip_frenzy_time - dt)
		if catnip_frenzy_time <= 0.0:
			_update_aura_buffs()
			
	# Tick Miso B5 global shadow reveal
	for t in towers:
		if t.cat_id == "miso" and t.tiers.get("path_b", 0) >= 5:
			miso_shadow_reveal_timer -= dt
			if miso_shadow_reveal_timer <= 0.0:
				miso_shadow_reveal_timer = 15.0
				for u in units:
					if u.is_alive and u.is_shadow:
						u.revealed_timer = maxf(u.revealed_timer, 3.0)
				_note_presentation("status", {"id": -1, "status": "all_seeing", "s": 0.0})
			break
	
	# Spawn pending wave units
	if round_in_progress:
		var remaining_spawns: Array[Dictionary] = []
		for sp in pending_spawns:
			sp.delay -= dt
			if sp.delay <= 0.0:
				spawn_unit(sp.config, 0.0)
			else:
				remaining_spawns.append(sp)
		pending_spawns = remaining_spawns
		
	# Tick ground hazard zones
	_tick_ground_zones(dt)
		
	# Tick hero
	if hero != null:
		hero.tick(dt)
		_tick_hero_combat(dt)
		
	# Tick towers
	for tower in towers:
		_tick_tower_combat(tower, dt)
		
	# Tick projectiles
	_tick_projectiles(dt)
	
	# Tick units & path movement
	var alive_units: Array[SimUnit] = []
	for u in units:
		if not u.is_alive:
			continue
		var tick_result := u.tick_status(dt)
		for packet in tick_result.get("damage_packets", []):
			if not u.is_alive:
				break
			var source_tower := _get_tower_by_id(int(packet.get("source_tower_id", -1)))
			var packet_type := int(packet.get("damage_type", SimConstants.DamageType.TRUE))
			var hit_res := u.hit(int(packet.get("amount", 0)), packet_type)
			_process_hit_result(source_tower, u, hit_res, packet_type)
		if not u.is_alive:
			continue
		u.tick_movement(dt)
		var p_len = get_path_length(u.path_index)
		if u.s >= p_len:
			# Unit leaks!
			var leak_rbe = u.calculate_current_rbe()
			
			# Sister Pebble L20 Balanced Books: first leak each round reduces life loss by 5 (min 1 lost if leak > 1)
			if hero != null and hero.id == "pebble" and hero.level >= 20 and not pebble_leak_reduction_used_this_round:
				pebble_leak_reduction_used_this_round = true
				var reduction = mini(5, maxi(0, leak_rbe - 1))
				leak_rbe -= reduction
				
			# Mittens L20 Last Thread: first leak of match prevents up to 20 lives
			if hero != null and hero.id == "mittens" and hero.level >= 20 and not hero.last_thread_used:
				hero.last_thread_used = true
				var prevented = mini(20, leak_rbe)
				leak_rbe -= prevented
				hero.base_damage += 1
				hero._recalculate_stats()
				_note_presentation("status", {"id": -1, "status": "last_thread", "x": hero.position.x, "y": hero.position.y})
			
			lives -= leak_rbe
			leak_history.append({
				"round": current_round,
				"unit_type": u.unit_type,
				"rbe": leak_rbe,
				"is_rat": u.is_rat,
				"is_shadow": u.is_shadow,
				"is_plated": u.is_plated,
				"path_index": u.path_index
			})
			_note_presentation("leak", {"id": u.id, "s": p_len, "rbe": leak_rbe, "path_index": u.path_index})
			u.is_alive = false
			if lives <= 0:
				lives = 0
				match_lost = true
				round_in_progress = false
				return
		else:
			alive_units.append(u)
	units = alive_units
	
	# Check round end
	if round_in_progress and pending_spawns.is_empty() and units.is_empty():
		round_in_progress = false
		_on_round_completed()

func _on_round_completed() -> void:
	economy.add_end_of_round_bonus(current_round)
	var extra_round_kibble := int(expansion_effects.get("end_round_kibble_flat", 0))
	if extra_round_kibble != 0:
		economy.kibble = maxi(0, economy.kibble + extra_round_kibble)
	pebble_leak_reduction_used_this_round = false
	
	# Sister Pebble end of round bonus
	if hero != null and hero.id == "pebble":
		var pebble_bonus = hero.end_round_kibble_base + hero.end_round_kibble_per_lvl * hero.level
		economy.kibble += pebble_bonus
		_note_presentation("kibble", {"amount": pebble_bonus, "x": hero.position.x, "y": hero.position.y})
	
	# Goldie income production
	for t in towers:
		if t.cat_id == "goldie":
			var income = 140
			if t.tiers.get("path_a", 0) >= 5:
				income = 600
			elif t.tiers.get("path_a", 0) >= 3:
				income = 400
			elif t.tiers.get("path_a", 0) >= 2:
				income = 280
			elif t.tiers.get("path_a", 0) >= 1:
				income = 200
			elif t.tiers.get("path_c", 0) >= 5:
				income = 800
			elif t.tiers.get("path_c", 0) >= 4:
				income = 300
			elif t.tiers.get("path_c", 0) >= 1:
				income = 160
				
			income += t.extra_round_kibble
			
			# Sister Pebble L7 Passive (Ledger): Goldie in range produces +10% kibble
			if hero != null and hero.id == "pebble" and hero.level >= 7:
				if hero.position.distance_to(t.position) <= hero.get_effective_range():
					income = int(round(income * 1.10))
					
			economy.kibble += income
			t.total_kibble_produced += income
			t.add_feat_xp(float(income) * 0.15)
	
	if skim_rounds_left > 0:
		skim_rounds_left -= 1
		if skim_rounds_left == 0:
			skim_bonus_active = false
	
	if hero != null:
		hero.add_round_xp(current_round)

	# Tick trick cooldowns
	for tk in trick_cooldowns.keys():
		trick_cooldowns[tk] = maxi(0, int(trick_cooldowns[tk]) - 1)
		
	if current_round >= max_rounds:
		match_won = true

func _tick_ground_zones(dt: float) -> void:
	var live_zones: Array[Dictionary] = []
	for z in ground_zones:
		z.duration -= dt
		var dps = float(z.get("dps", 0.0))
		var radius = float(z.get("radius", 60.0))
		var zpos: Vector2 = z.position
		var dtype = int(z.get("damage_type", SimConstants.DamageType.BITE))
		var source_id := int(z.get("source_tower_id", -1))
		var zone_kind := str(z.get("kind", "burn"))
		for u in units:
			if not u.is_alive:
				continue
			var upos = get_point_on_path(u.s, u.path_index)
			if upos.distance_to(zpos) <= radius:
				if dps > 0.0:
					if zone_kind == "acid":
						u.status.apply_corrosion(dps, 1.0, source_id)
					else:
						u.status.apply_burn(dps, 1.0, dtype, source_id)
				var slow_val = float(z.get("slow", 0.0))
				if slow_val > 0.0:
					u.status.apply_slow(1.0 - slow_val, 1.0)
		if z.duration > 0.0:
			live_zones.append(z)
	ground_zones = live_zones

func _tick_tower_combat(tower: SimTower, dt: float) -> void:
	if tower.cat_id == "goldie" or tower.cat_id == "miso":
		# Support den cats, no direct attack
		return
		
	if tower.cat_id == "marlow":
		_tick_marlow_sonar(tower, dt)
	if tower.tick_cooldown(dt):
		var ignores_sight = (tower.cat_id == "biscuit" or tower.cat_id == "sable")
		var target = _find_target(tower.position, tower.get_effective_range(), tower.get_effective_see_shadow(), tower.target_priority, tower.full_track_range, ignores_sight)
		if target != null:
			_fire_tower_attack(tower, target)

func _tick_hero_combat(dt: float) -> void:
	hero.attack_timer -= dt
	if hero.attack_timer <= 0.0:
		var target = _find_target(hero.position, hero.get_effective_range(), hero.see_shadow, SimConstants.TargetPriority.FIRST, false, false)
		if target != null:
			hero.attack_timer = hero.get_effective_cooldown()
			var target_pos = get_point_on_path(target.s, target.path_index)
			_note_presentation("fire", {"id": -1, "cat": hero.id, "x": hero.position.x, "y": hero.position.y, "target_s": target.s, "damage_type": hero.damage_type})
			
			if hero.id == "duchess":
				var hit_res = target.hit(hero.get_effective_damage(), hero.damage_type)
				if hit_res.damage_dealt > 0:
					hero.damage_this_round += hit_res.damage_dealt
					hero.total_damage += hit_res.damage_dealt
				target.status.apply_burn(hero.burn_dps, hero.burn_duration, hero.damage_type)
				_process_hit_result(null, target, hit_res, hero.damage_type)
			elif hero.id == "baron":
				proj_id_counter += 1
				var p = SimProjectile.new()
				p.setup_lob(
					proj_id_counter,
					-1,
					target_pos,
					hero.get_effective_damage(),
					SimConstants.DamageType.BLAST,
					hero.pierce,
					hero.explosion_radius,
					0.4
				)
				projectiles.append(p)
				if hero.level >= 20 and hero.keelhaul_timer <= 0.0:
					hero.keelhaul_timer = 8.0
					if target.is_plated:
						if target.unit_type == "matriarch":
							pass
						else:
							target.is_plated = false
							_note_presentation("status", {"id": target.id, "status": "unplated", "s": target.s})
			elif hero.id == "mittens":
				var hit_res = target.hit(hero.get_effective_damage(), hero.damage_type)
				if hit_res.damage_dealt > 0:
					hero.damage_this_round += hit_res.damage_dealt
					hero.total_damage += hit_res.damage_dealt
				_process_hit_result(null, target, hit_res, hero.damage_type)
				if hero.spool_barrage_timer > 0.0:
					for _i in range(5):
						proj_id_counter += 1
						var p = SimProjectile.new()
						p.setup_linear(
							proj_id_counter,
							-1,
							hero.position,
							target_pos,
							hero.get_effective_damage(),
							hero.damage_type,
							2,
							500.0,
							true
						)
						projectiles.append(p)
			else:
				var hit_res = target.hit(hero.get_effective_damage(), hero.damage_type)
				if hit_res.damage_dealt > 0:
					hero.damage_this_round += hit_res.damage_dealt
					hero.total_damage += hit_res.damage_dealt
				_process_hit_result(null, target, hit_res, hero.damage_type)

func _fire_tower_attack(tower: SimTower, target: SimUnit) -> void:
	var target_pos = get_point_on_path(target.s, target.path_index)
	_note_presentation("fire", {"id": tower.instance_id, "cat": tower.cat_id, "x": tower.position.x, "y": tower.position.y, "target_x": target_pos.x, "target_y": target_pos.y, "target_s": target.s, "damage_type": tower.damage_type})
	
	if tower.cat_id == "pudding":
		# Frostpaw area pulse
		_note_presentation("frost_pulse", {"id": tower.instance_id, "x": tower.position.x, "y": tower.position.y, "radius": tower.range_radius})
		var freeze_time = 1.0
		if tower.tiers.get("path_a", 0) >= 3:
			freeze_time = 2.0
		elif tower.tiers.get("path_a", 0) >= 1:
			freeze_time = 1.5
			
		for u in units:
			if not u.is_alive:
				continue
			var upos = get_point_on_path(u.s, u.path_index)
			if upos.distance_to(tower.position) <= tower.range_radius:
				if u.immunities.has("Freeze") or u.unit_type == "frost":
					_note_presentation("blocked", {"id": u.id, "blocked_by": "frost", "s": u.s})
					continue
				var applied := u.status.apply_freeze(0.3 if u.is_rat else freeze_time)
				if applied:
					_note_presentation("status", {"id": u.id, "status": "freeze", "s": u.s})
				elif u.unit_type == "matriarch":
					_note_presentation("blocked", {"id": u.id, "blocked_by": "matriarch", "s": u.s})
				if tower.damage > 0:
					var hit_res = u.hit(tower.damage, tower.damage_type)
					_process_hit_result(tower, u, hit_res)
	elif tower.cat_id == "nibs":
		# Circle Pouncer arcs
		_note_presentation("slash", {"id": tower.instance_id, "x": tower.position.x, "y": tower.position.y, "radius": tower.range_radius})
		var hits = 0
		var max_targets = 8 + (2 * tower.tiers.get("path_a", 0))
		for u in units:
			if not u.is_alive:
				continue
			var upos = get_point_on_path(u.s, u.path_index)
			if upos.distance_to(tower.position) <= tower.range_radius:
				var hit_res = u.hit(tower.damage, tower.damage_type)
				_process_hit_result(tower, u, hit_res)
				hits += 1
				if hits >= max_targets:
					break
	elif tower.cat_id == "bub":
		_fire_bub_attack(tower, target_pos)
	elif tower.cat_id == "biscuit":
		# Lobbed explosion
		proj_id_counter += 1
		var p = SimProjectile.new()
		p.setup_lob(
			proj_id_counter,
			tower.instance_id,
			target_pos,
			tower.damage,
			tower.damage_type,
			tower.pierce,
			float(tower.cat_data.get("base", {}).get("radius", 45.0)),
			float(tower.cat_data.get("base", {}).get("travel_time", 0.4)),
			tower.position
		)
		projectiles.append(p)
	elif tower.cat_id == "sable":
		# Hitscan instant shot
		var hit_res = target.hit(tower.damage, tower.damage_type)
		_process_hit_result(tower, target, hit_res)
	elif tower.cat_id == "marlow":
		_fire_marlow_attack(tower, target, target_pos)
	else:
		# Standard projectile
		proj_id_counter += 1
		var p = SimProjectile.new()
		p.setup_linear(
			proj_id_counter,
			tower.instance_id,
			tower.position,
			target_pos,
			tower.damage,
			tower.damage_type,
			tower.pierce,
			tower.get_effective_projectile_speed(),
			tower.tiers.get("path_c", 0) >= 3
		)
		projectiles.append(p)

func _fire_bub_attack(tower: SimTower, target_pos: Vector2) -> void:
	tower.successful_attacks += 1
	var base: Dictionary = tower.cat_data.get("base", {})
	var puddle_every := int(_cat_tier_value(tower, "puddle_every"))
	var creates_puddle := puddle_every > 0 and tower.successful_attacks % puddle_every == 0
	var payload := {
		"effect": "corrosion",
		"corrosion_dps": _cat_tier_value(tower, "corrosion_dps", float(base.get("corrosion_dps", 1.0))),
		"corrosion_duration": _cat_tier_value(tower, "corrosion_duration", float(base.get("corrosion_duration", 3.0))) + tower.corrosion_duration_bonus,
		"spawn_puddle": creates_puddle,
		"puddle_radius": _cat_tier_value(tower, "puddle_radius"),
		"puddle_dps": _cat_tier_value(tower, "puddle_dps"),
		"puddle_duration": _cat_tier_value(tower, "puddle_duration")
	}
	proj_id_counter += 1
	var projectile := SimProjectile.new()
	projectile.setup_lob(
		proj_id_counter,
		tower.instance_id,
		target_pos,
		tower.get_effective_damage(),
		SimConstants.DamageType.ACID,
		tower.get_effective_pierce(),
		_cat_tier_value(tower, "radius", float(base.get("radius", 18.0))),
		float(base.get("travel_time", 0.35)),
		tower.position,
		payload
	)
	projectiles.append(projectile)

func _marlow_tier_value(tower: SimTower, key: String, fallback: float = 0.0) -> float:
	var value := fallback
	var paths_data: Dictionary = tower.cat_data.get("paths", {})
	for path_key in paths_data:
		var tiers: Array = paths_data[path_key].get("tiers", [])
		for tier_index in range(mini(int(tower.tiers.get(path_key, 0)), tiers.size())):
			if tiers[tier_index].has(key):
				value = float(tiers[tier_index][key])
	return value

func _fire_marlow_attack(tower: SimTower, target: SimUnit, target_pos: Vector2) -> void:
	# Named components: a rat-targeting harpoon and water-dive volley.
	var base_shots := 2.0 if _marlow_tier_value(tower, "double_spit") > 0.0 else 1.0
	var shots := maxi(1, int(_marlow_tier_value(tower, "projectiles", base_shots)))
	if target.is_rat and _marlow_tier_value(tower, "harpoon_rat_damage") > 0.0:
		_fire_marlow_harpoon(tower, target)
		return
	for _shot in range(shots):
		proj_id_counter += 1
		var projectile := SimProjectile.new()
		projectile.setup_linear(proj_id_counter, tower.instance_id, tower.position, target_pos, tower.damage, tower.damage_type, tower.pierce, tower.get_effective_projectile_speed(), _marlow_tier_value(tower, "dive") > 0.0)
		projectiles.append(projectile)

func _fire_marlow_harpoon(tower: SimTower, target: SimUnit) -> void:
	var damage := tower.damage + int(_marlow_tier_value(tower, "harpoon_rat_damage"))
	var hit_res := target.hit(damage, tower.damage_type)
	_process_hit_result(tower, target, hit_res)
	_note_presentation("harpoon", {"id": tower.instance_id, "target": target.id, "s": target.s})

func _tick_marlow_sonar(tower: SimTower, dt: float) -> void:
	var interval := _marlow_tier_value(tower, "sonar_interval")
	if interval <= 0.0:
		return
	var elapsed := float(marlow_sonar_elapsed.get(tower.instance_id, 0.0)) + dt
	if elapsed < interval:
		marlow_sonar_elapsed[tower.instance_id] = elapsed
		return
	marlow_sonar_elapsed[tower.instance_id] = 0.0
	var reveal := _marlow_tier_value(tower, "sonar_reveal", 1.5)
	for unit in units:
		if unit.is_alive and unit.is_shadow:
			unit.revealed_timer = maxf(unit.revealed_timer, reveal)
	_note_presentation("sonar", {"id": tower.instance_id, "x": tower.position.x, "y": tower.position.y})

func _tick_projectiles(dt: float) -> void:
	var active_projs: Array[SimProjectile] = []
	for p in projectiles:
		if not p.is_active:
			continue
			
		var detonated = p.tick(dt)
		if p.is_explosion and detonated:
			# Explosion detonates: hits units within radius up to pierce
			var is_acid_flask := str(p.payload.get("effect", "")) == "corrosion"
			_note_presentation("acid_splash" if is_acid_flask else "explosion", {"x": p.target_position.x, "y": p.target_position.y, "radius": p.radius, "cat": "bub" if is_acid_flask else "biscuit"})
			var hits = 0
			var src_tower = _get_tower_by_id(p.source_cat_id)
			for u in units:
				if not u.is_alive or p.already_hit_unit_ids.has(u.id):
					continue
				var upos = get_point_on_path(u.s, u.path_index)
				if upos.distance_to(p.target_position) <= p.radius:
					p.already_hit_unit_ids[u.id] = true
					var hit_res = u.hit(p.damage, p.damage_type)
					if is_acid_flask and u.is_alive:
						u.status.apply_corrosion(float(p.payload.get("corrosion_dps", 0.0)), float(p.payload.get("corrosion_duration", 0.0)), p.source_cat_id)
					_process_hit_result(src_tower, u, hit_res)
					hits += 1
					if hits >= p.pierce_left:
						break
			if is_acid_flask and bool(p.payload.get("spawn_puddle", false)):
				ground_zones.append({
					"kind": "acid",
					"position": p.target_position,
					"radius": float(p.payload.get("puddle_radius", 0.0)),
					"dps": float(p.payload.get("puddle_dps", 0.0)),
					"duration": float(p.payload.get("puddle_duration", 0.0)),
					"damage_type": SimConstants.DamageType.ACID,
					"source_tower_id": p.source_cat_id
				})
				_note_presentation("acid_pool", {"x": p.target_position.x, "y": p.target_position.y, "radius": float(p.payload.get("puddle_radius", 0.0))})
			p.is_active = false
		elif not p.is_explosion:
			# Check sight blockers collision
			if not sight_blockers.is_empty():
				for blocker in sight_blockers:
					if blocker.has_point(p.position):
						p.is_active = false
						_note_presentation("blocked", {"id": -1, "blocked_by": "sight_blocker", "x": p.position.x, "y": p.position.y})
						break
			if not p.is_active:
				continue
			# Collision check with units
			for u in units:
				if not u.is_alive or p.already_hit_unit_ids.has(u.id):
					continue
				var upos = get_point_on_path(u.s, u.path_index)
				if upos.distance_to(p.position) <= 20.0:
					p.already_hit_unit_ids[u.id] = true
					var hit_res = u.hit(p.damage, p.damage_type)
					var src_tower = _get_tower_by_id(p.source_cat_id)
					_process_hit_result(src_tower, u, hit_res)
					p.pierce_left -= 1
					if p.pierce_left <= 0:
						p.is_active = false
						break
		if p.is_active:
			active_projs.append(p)
	projectiles = active_projs

func _process_hit_result(src_tower: SimTower, unit: SimUnit, hit_res: Dictionary, event_damage_type: int = -1) -> void:
	if hit_res.get("blocked_by", "") != "":
		var blk = str(hit_res.blocked_by).to_lower()
		blocked_immunity_counts[blk] = blocked_immunity_counts.get(blk, 0) + 1
		_note_presentation("blocked", {"id": unit.id, "blocked_by": hit_res.blocked_by, "s": unit.s})
	elif hit_res.damage_dealt > 0:
		var visual_damage_type := src_tower.damage_type if src_tower != null else event_damage_type
		_note_presentation("hit", {"id": unit.id, "damage": hit_res.damage_dealt, "damage_type": visual_damage_type, "s": unit.s})
	if hit_res.damage_dealt > 0:
		total_hp_removed += int(hit_res.hp_removed)
		var bonus_mult = 1.20 if skim_bonus_active else 1.00
		var kibble_earned := int(round(float(economy.add_pop_damage(hit_res.hp_removed, current_round, hit_res.shell_bounty)) * bonus_mult))
		_note_presentation("kibble", {"amount": kibble_earned, "s": unit.s})
		if src_tower != null:
			_award_bub_midas(src_tower, int(hit_res.hp_removed), unit.s)
			src_tower.damage_dealt += hit_res.damage_dealt
			if hit_res.coat_popped:
				src_tower.pops_count += 1
			src_tower.add_feat_xp(float(hit_res.damage_dealt) * 0.4 + (3.0 if hit_res.coat_popped else 0.0))
			for src_id in src_tower.aura_sources:
				var buff_t = _get_tower_by_id(src_id)
				if buff_t != null and buff_t.cat_id == "miso":
					buff_t.add_feat_xp(float(hit_res.damage_dealt) * 0.25)
					buff_t.total_buff_damage_assisted += hit_res.damage_dealt
			if unit.status.freeze_time > 0.0:
				for t in towers:
					if t.cat_id == "pudding" and t.position.distance_to(get_point_on_path(unit.s, unit.path_index)) <= t.get_effective_range():
						t.freeze_assists += 1
						t.add_feat_xp(float(hit_res.damage_dealt) * 0.25)
						break
	for coat in hit_res.get("popped_coats", []):
		_note_presentation("pop", {"id": unit.id, "coat": coat, "s": unit.s, "is_rat": unit.is_rat, "unit_type": unit.unit_type})
	_spawn_hit_children(unit.s, hit_res.children_to_spawn, unit.path_index, unit.path_id)

func _award_bub_midas(tower: SimTower, hp_removed: int, path_s: float) -> void:
	if tower.cat_id != "bub" or hp_removed <= 0:
		return
	var ratio := _cat_tier_value(tower, "midas_ratio") + tower.midas_ratio_bonus
	var cap := int(_cat_tier_value(tower, "midas_cap")) + tower.midas_cap_bonus
	var remaining := maxi(0, cap - tower.midas_kibble_this_round)
	if ratio <= 0.0 or remaining <= 0:
		return
	tower.midas_fraction += float(hp_removed) * ratio
	var earned := mini(remaining, int(floor(tower.midas_fraction + 0.000001)))
	if earned <= 0:
		return
	tower.midas_fraction -= earned
	tower.midas_kibble_this_round += earned
	tower.total_kibble_produced += earned
	economy.kibble += earned
	tower.add_feat_xp(float(earned) * 0.15)
	_note_presentation("kibble", {"amount": earned, "s": path_s, "source": "midas", "tower_id": tower.instance_id})

func _spawn_hit_children(path_s: float, children_configs: Array, path_idx: int = 0, p_id: String = "") -> void:
	for ch in children_configs:
		var child_cfg = ch.duplicate()
		if not child_cfg.has("path_index"):
			child_cfg["path_index"] = path_idx
		if not child_cfg.has("path_id") and p_id != "":
			child_cfg["path_id"] = p_id
		var child := spawn_unit(child_cfg, path_s)
		_note_presentation("child", {"id": child.id, "coat": child.unit_type, "s": path_s, "path_index": path_idx})

func _get_tower_by_id(tid: int) -> SimTower:
	for t in towers:
		if t.instance_id == tid:
			return t
	return null

func _find_target(
	origin: Vector2,
	range_r: float,
	has_night_eye: bool,
	priority: int,
	full_track: bool,
	ignores_sight: bool = false
) -> SimUnit:
	var best_unit: SimUnit = null
	var best_score: float = -999999.0
	
	for u in units:
		if not u.is_alive:
			continue
		var effective_night_eye = has_night_eye or (lantern_reveal_time > 0.0)
		if not u.can_be_targeted(effective_night_eye):
			continue
		var upos = get_point_on_path(u.s, u.path_index)
		if not full_track and upos.distance_to(origin) > range_r:
			continue
		if not ignores_sight and not sight_blockers.is_empty():
			if not has_line_of_sight(origin, upos):
				continue
			
		var score: float = 0.0
		match priority:
			SimConstants.TargetPriority.FIRST:
				score = u.s
			SimConstants.TargetPriority.LAST:
				score = -u.s
			SimConstants.TargetPriority.STRONG:
				score = float(u.calculate_current_rbe()) * 10000.0 + u.s
			SimConstants.TargetPriority.CLOSE:
				score = -upos.distance_to(origin)
			SimConstants.TargetPriority.RATS_FIRST:
				score = (100000.0 if u.is_rat else 0.0) + u.s
			_:
				score = u.s
				
		if score > best_score:
			best_score = score
			best_unit = u
			
	return best_unit

func _distance_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab = b - a
	var ab_len_sq = ab.length_squared()
	if ab_len_sq == 0.0:
		return p.distance_to(a)
	var t = clampf((p - a).dot(ab) / ab_len_sq, 0.0, 1.0)
	var projection = a + ab * t
	return p.distance_to(projection)

func _distance_to_path(pos: Vector2) -> float:
	if paths.is_empty():
		var p0 = Vector2(40.0, 100.0)
		var p1 = Vector2(640.0, 100.0)
		var p2 = Vector2(640.0, 400.0)
		var p3 = Vector2(340.0, 400.0)
		var d1 = _distance_to_segment(pos, p0, p1)
		var d2 = _distance_to_segment(pos, p1, p2)
		var d3 = _distance_to_segment(pos, p2, p3)
		return minf(d1, minf(d2, d3))
		
	var min_d: float = 999999.0
	for p_info in paths:
		var pts: Array = p_info.points
		for i in range(pts.size() - 1):
			var d = _distance_to_segment(pos, pts[i], pts[i + 1])
			if d < min_d:
				min_d = d
	return min_d

func _point_in_zone(pos: Vector2, zone: Dictionary) -> bool:
	if zone.has("radius"):
		return pos.distance_to(Vector2(float(zone.get("x", 0.0)), float(zone.get("y", 0.0)))) <= float(zone.get("radius", 0.0))
	return Rect2(float(zone.get("x", 0.0)), float(zone.get("y", 0.0)), float(zone.get("width", 0.0)), float(zone.get("height", 0.0))).has_point(pos)

func _in_any_zone(pos: Vector2, zone_name: String) -> bool:
	for zone in placement_zones.get(zone_name, []):
		if zone is Dictionary and _point_in_zone(pos, zone):
			return true
	return false

func _obstacle_rect(obstacle: Dictionary) -> Rect2:
	var base: Dictionary = obstacle.get("base", obstacle)
	return Rect2(float(base.get("x", 0.0)), float(base.get("y", 0.0)), float(base.get("width", base.get("w", 0.0))), float(base.get("height", base.get("h", 0.0))))

func get_removable_obstacles() -> Array[Dictionary]:
	var active: Array[Dictionary] = []
	for obstacle in removable_obstacles:
		if not cleared_obstacle_ids.has(str(obstacle.get("id", ""))):
			active.append(obstacle.duplicate(true))
	return active

func get_obstacle_at(pos: Vector2) -> Dictionary:
	for obstacle in removable_obstacles:
		var obstacle_id := str(obstacle.get("id", ""))
		if not cleared_obstacle_ids.has(obstacle_id) and _obstacle_rect(obstacle).has_point(pos):
			return obstacle.duplicate(true)
	return {}

func can_clear_obstacle(obstacle_id: String) -> Dictionary:
	if round_in_progress:
		return {"allowed": false, "reason": "Clear between rounds"}
	for obstacle in removable_obstacles:
		if str(obstacle.get("id", "")) != obstacle_id:
			continue
		if cleared_obstacle_ids.has(obstacle_id):
			return {"allowed": false, "reason": "Already cleared", "id": obstacle_id}
		var price := int(obstacle.get("cost", 0))
		if not economy.can_afford(price):
			return {"allowed": false, "reason": "Need %d Kibble" % price, "id": obstacle_id, "price": price}
		return {"allowed": true, "reason": "OK", "id": obstacle_id, "price": price, "obstacle": obstacle.duplicate(true)}
	return {"allowed": false, "reason": "Unknown obstacle", "id": obstacle_id}

func clear_obstacle(obstacle_id: String) -> bool:
	var check := can_clear_obstacle(obstacle_id)
	if not check.get("allowed", false):
		return false
	var price := int(check.get("price", 0))
	if not economy.spend(price):
		return false
	cleared_obstacle_ids[obstacle_id] = true
	_note_presentation("clear_obstacle", {"id": obstacle_id, "price": price})
	replay.log_action(tick_counter, "clear_obstacle", {"id": obstacle_id, "price": price})
	return true

func _placement_surface_ok(mask: Array, pos: Vector2) -> Dictionary:
	var wants_water := mask.any(func(value): return str(value).to_lower() == "water")
	var wants_land := mask.any(func(value): return str(value).to_lower() == "land")
	var wants_perch := mask.any(func(value): return str(value).to_lower() == "perch")
	var in_water := _in_any_zone(pos, "water")
	var in_land := _in_any_zone(pos, "land") and not in_water
	var in_perch := _in_any_zone(pos, "perches")
	if (wants_water and in_water) or (wants_land and in_land) or (wants_perch and in_perch):
		return {"valid": true}
	if wants_water:
		return {"valid": false, "reason": "Requires water"}
	return {"valid": false, "reason": "Requires land or perch"}

func can_place_tower_at(cat_id: String, pos: Vector2) -> Dictionary:
	var cdata: Dictionary = cat_blueprints.get(cat_id, {})
	var base_cost = int(cdata.get("cost", 200))
	var discounts = get_placement_discounts(pos)
	var price = economy.calculate_price(base_cost, discounts)
	var footprint = float(cdata.get("footprint_radius", 20.0)) * (1.0 + float(expansion_effects.get("footprint_percent", 0.0)) / 100.0)
	
	if not economy.can_afford(price):
		return {"valid": false, "reason": "Need %d Kibble" % price, "code": "kibble", "price": price}
	var surface := _placement_surface_ok(cdata.get("placement_mask", ["Land"]), pos)
	if not surface.get("valid", false):
		return {"valid": false, "reason": surface.get("reason", "Invalid surface"), "code": "surface", "price": price}
		
	# Path clearance (track half-width is 15.0)
	var d_track = _distance_to_path(pos)
	if d_track < footprint + 16.0:
		return {"valid": false, "reason": "Cannot place on alley path", "code": "road", "price": price}
		
	# Sight blocker / prop clearance
	for blocker in sight_blockers:
		if blocker.grow(footprint).has_point(pos):
			return {"valid": false, "reason": "Blocked by permanent obstacle", "code": "permanent_obstacle", "price": price}
	for obstacle in removable_obstacles:
		var obstacle_id := str(obstacle.get("id", ""))
		if not cleared_obstacle_ids.has(obstacle_id) and _obstacle_rect(obstacle).grow(footprint).has_point(pos):
			return {"valid": false, "reason": "Blocked by removable clutter", "code": "removable_obstacle", "blocker_id": obstacle_id, "price": price}
		
	# Tower collision clearance
	for t in towers:
		if pos.distance_to(t.position) < footprint + t.footprint_radius:
			return {"valid": false, "reason": "Overlaps another cat", "code": "cat", "price": price}
			
	# Hero clearance
	if hero != null and pos.distance_to(hero.position) < footprint + 20.0:
		return {"valid": false, "reason": "Overlaps hero", "code": "hero", "price": price}
		
	return {"valid": true, "reason": "OK", "code": "ok", "price": price, "footprint": footprint}

func can_place_hero_at(hero_id: String, pos: Vector2) -> Dictionary:
	if hero != null:
		return {"valid": false, "reason": "Hero already deployed", "code": "hero"}
	var hdata: Dictionary = hero_blueprints.get(hero_id, {})
	var cost = int(hdata.get("place_cost", 600))
	var price = economy.calculate_price(cost)
	var footprint = 20.0
	
	if not economy.can_afford(price):
		return {"valid": false, "reason": "Need %d Kibble" % price, "code": "kibble", "price": price}
	var surface := _placement_surface_ok(hdata.get("placement_mask", ["Land"]), pos)
	if not surface.get("valid", false):
		return {"valid": false, "reason": surface.get("reason", "Invalid surface"), "code": "surface", "price": price}
		
	var d_track = _distance_to_path(pos)
	if d_track < footprint + 16.0:
		return {"valid": false, "reason": "Cannot place on alley path", "code": "road", "price": price}
		
	# Sight blocker / prop clearance
	for blocker in sight_blockers:
		if blocker.grow(footprint).has_point(pos):
			return {"valid": false, "reason": "Blocked by permanent obstacle", "code": "permanent_obstacle", "price": price}
	for obstacle in removable_obstacles:
		var obstacle_id := str(obstacle.get("id", ""))
		if not cleared_obstacle_ids.has(obstacle_id) and _obstacle_rect(obstacle).grow(footprint).has_point(pos):
			return {"valid": false, "reason": "Blocked by removable clutter", "code": "removable_obstacle", "blocker_id": obstacle_id, "price": price}
		
	for t in towers:
		if pos.distance_to(t.position) < footprint + t.footprint_radius:
			return {"valid": false, "reason": "Overlaps another cat", "code": "cat", "price": price}
			
	return {"valid": true, "reason": "OK", "code": "ok", "price": price, "footprint": footprint}

func get_pending_feat_tower() -> SimTower:
	for t in towers:
		if t.pending_feat_choice:
			return t
	return null

func reroll_tower_feats(tower: SimTower) -> bool:
	if tower.reroll_used:
		return false
	if not economy.spend(150):
		return false
	tower.reroll_used = true
	replay.log_action(tick_counter, "feat_reroll", {"tower_id": tower.instance_id})
	return true

func _find_nearest_track_s(pos: Vector2, p_idx: int = 0) -> float:
	var best_s = 0.0
	var best_dist = 999999.0
	var total_len = get_path_length(p_idx)
	var step = 15.0
	var cur_s = 0.0
	while cur_s <= total_len:
		var pt = get_point_on_path(cur_s, p_idx)
		var d = pt.distance_to(pos)
		if d < best_dist:
			best_dist = d
			best_s = cur_s
		cur_s += step
	return best_s

func trigger_tower_ability(tower: SimTower) -> bool:
	if tower == null:
		return false
	if tower.cat_id == "miso":
		var c_tier = tower.tiers.get("path_c", 0)
		if c_tier >= 4:
			miso_bell_timer = 12.0 if c_tier >= 5 else 8.0
			miso_bell_speed = 1.00 if c_tier >= 5 else 0.70
			miso_bell_damage = 1 if c_tier >= 5 else 0
			_update_aura_buffs()
			_note_presentation("ability", {"id": tower.instance_id, "cat": tower.cat_id, "x": tower.position.x, "y": tower.position.y})
			replay.log_action(tick_counter, "tower_ability", {"tower_id": tower.instance_id})
			return true
	return false

func trigger_hero_ability(slot: int) -> bool:
	if hero == null:
		return false
	var res = hero.trigger_ability(slot)
	if not res.get("triggered", false):
		return false
	if hero.id == "mittens":
		if slot == 1:
			# Pin Cushion: 10 needles in ring
			for i in range(10):
				var angle = (float(i) / 10.0) * TAU
				var dir = Vector2(cos(angle), sin(angle))
				proj_id_counter += 1
				var p = SimProjectile.new()
				p.setup_linear(
					proj_id_counter,
					-1,
					hero.position,
					hero.position + dir * 350.0,
					2,
					SimConstants.DamageType.CLAW,
					4,
					450.0,
					false
				)
				projectiles.append(p)
		elif slot == 2:
			# Spool Barrage: for 6s fires 5 seeking needles per basic attack
			hero.spool_barrage_timer = 6.0
	elif hero.id == "duchess":
		if slot == 1:
			# Heatwave: ignites all enemies in 100 radius for 4 dps Burn over 4s (or 6s if Hearth)
			var burn_dur = 6.0 if hero.level >= 7 else 4.0
			for u in units:
				if u.is_alive:
					var upos = get_point_on_path(u.s, u.path_index)
					if upos.distance_to(hero.position) <= 100.0:
						u.status.apply_burn(4.0, burn_dur, SimConstants.DamageType.MAGIC if hero.level < 8 else SimConstants.DamageType.VOID)
						_note_presentation("status", {"id": u.id, "status": "burn", "s": u.s})
		elif slot == 2:
			# Chili Heart: fire zone on nearest track point for 8s, dealing 8 dps
			var nearest_s = _find_nearest_track_s(hero.position)
			var zone_pos = get_point_on_path(nearest_s)
			ground_zones.append({
				"type": "fire",
				"position": zone_pos,
				"radius": 60.0,
				"dps": 8.0,
				"duration": 8.0,
				"damage_type": SimConstants.DamageType.MAGIC if hero.level < 8 else SimConstants.DamageType.VOID,
				"slow": 0.0
			})
	elif hero.id == "baron":
		if slot == 1:
			# Depth Charge: rolling concussion along 180 units of track, 6 Blast damage
			var center_s = 0.0
			var target = _find_target(hero.position, hero.get_effective_range(), hero.see_shadow, SimConstants.TargetPriority.FIRST, false)
			if target != null:
				center_s = target.s
			else:
				center_s = _find_nearest_track_s(hero.position)
			for u in units:
				if u.is_alive and absf(u.s - center_s) <= 90.0:
					var hit_res = u.hit(6, SimConstants.DamageType.BLAST)
					_process_hit_result(null, u, hit_res, SimConstants.DamageType.BLAST)
		elif slot == 2:
			# Broadside: launches 3 massive bombs (15 Blast damage each, 60 radius)
			var target = _find_target(hero.position, hero.get_effective_range(), hero.see_shadow, SimConstants.TargetPriority.FIRST, false)
			var base_s = target.s if target != null else _find_nearest_track_s(hero.position)
			for offset in [-60.0, 0.0, 60.0]:
				var bomb_s = maxf(0.0, base_s + offset)
				var bomb_pos = get_point_on_path(bomb_s)
				proj_id_counter += 1
				var p = SimProjectile.new()
				p.setup_lob(
					proj_id_counter,
					-1,
					bomb_pos,
					15,
					SimConstants.DamageType.BLAST,
					16,
					60.0,
					0.5
				)
				projectiles.append(p)
	elif hero.id == "pebble":
		if slot == 1:
			# Skim: pop kibble +20% during following round
			skim_bonus_active = true
			skim_rounds_left = 1
		elif slot == 2:
			# Audit: instantly awards 500 + 30 * level kibble
			var audit_kibble = 500 + 30 * hero.level
			economy.kibble += audit_kibble
			_note_presentation("kibble", {"amount": audit_kibble, "x": hero.position.x, "y": hero.position.y})
			
	_note_presentation("ability", {"id": -1, "hero": hero.id, "slot": slot, "x": hero.position.x, "y": hero.position.y})
	replay.log_action(tick_counter, "hero_ability", {"slot": slot})
	return true

func use_trick(trick_id: String, target_pos: Vector2 = Vector2.ZERO) -> Dictionary:
	if mode == SimConstants.GameMode.BARE_PAW:
		return {"success": false, "reason": "bare_paw"}
	if trick_cooldowns.get(trick_id, 0) > 0:
		return {"success": false, "reason": "cooldown", "rounds_left": trick_cooldowns[trick_id]}

	var tdata: Dictionary = tricks_data.get("tricks", {}).get(trick_id, {})
	if tdata.is_empty():
		return {"success": false, "reason": "unknown_trick"}

	var kib_cost = int(tdata.get("kibble_cost", 50))
	if not economy.spend(kib_cost):
		return {"success": false, "reason": "kibble"}

	trick_cooldowns[trick_id] = int(tdata.get("cooldown_rounds", 15))

	match trick_id:
		"tuna_strike":
			var dmg = int(tdata.get("damage", 12))
			var rad = float(tdata.get("radius", 60.0))
			var cap = int(tricks_data.get("max_damage_on_matriarch", 1100))
			for u in units:
				if not u.is_alive:
					continue
				var upos = get_point_on_path(u.s, u.path_index)
				if upos.distance_to(target_pos) <= rad:
					var effective_dmg = dmg
					if u.unit_type == "matriarch":
						effective_dmg = mini(effective_dmg, cap)
					var hit_res = u.hit(effective_dmg, SimConstants.DamageType.BITE)
					_process_hit_result(null, u, hit_res, SimConstants.DamageType.BITE)
		"night_lantern":
			lantern_reveal_time = float(tdata.get("reveal_shadow_duration", 12.0))
		"yarn_snare":
			var hold_mice = float(tdata.get("hold_mice_duration", 6.0))
			var slow_rat = float(tdata.get("slow_rat_speed", 0.8))
			var slow_dur = float(tdata.get("slow_rat_duration", 3.0))
			for u in units:
				if not u.is_alive:
					continue
				if not u.is_rat:
					u.status.apply_stun(hold_mice)
				elif u.unit_type != "matriarch":
					u.status.apply_slow(slow_rat, slow_dur)
		"catnip_frenzy":
			catnip_frenzy_time = float(tdata.get("duration", 8.0))
			_update_aura_buffs()
		"fish_rain":
			economy.kibble += 75
			_note_presentation("kibble", {"amount": 75, "x": target_pos.x, "y": target_pos.y})
		"nine_life_pulse":
			lives = mini(max_lives, lives + 10)
		"hairball_volley":
			if hero != null:
				trigger_hero_ability(1)

	_note_presentation("trick", {"id": trick_id, "x": target_pos.x, "y": target_pos.y})
	replay.log_action(tick_counter, "use_trick", {"trick_id": trick_id, "x": target_pos.x, "y": target_pos.y})
	return {"success": true, "trick_id": trick_id}



