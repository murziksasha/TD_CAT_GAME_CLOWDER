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
var path_length: float = 1200.0
var paths: Array[Dictionary] = []
var sight_blockers: Array[Rect2] = []
var map_data: Dictionary = {}
var placement_zones: Dictionary = {}

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
	replay.setup(p_seed, map_id, mode)
	
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

func _init_default_sunny_path() -> void:
	map_id = "sunny_gutter"
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
	placement_zones = {"land": [{"x": 0.0, "y": 0.0, "width": 1280.0, "height": 720.0}], "water": [], "perches": []}

func load_map_data(p_map_data: Dictionary) -> void:
	map_data = p_map_data
	map_id = p_map_data.get("id", "sunny_gutter")
	paths.clear()
	sight_blockers.clear()
	placement_zones = p_map_data.get("placement_zones", {}).duplicate(true)
	
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
			
		var total_len: float = cum_lengths[-1]
		var override_len: float = float(rp.get("length", total_len))
		paths.append({
			"id": rp.get("id", "path_%d" % i),
			"points": pts,
			"cum_lengths": cum_lengths,
			"length": override_len if override_len > 0.0 else total_len
		})
		
	if not paths.is_empty():
		path_length = paths[0].length
	else:
		path_length = float(p_map_data.get("path_length", 1200.0))
		
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

func place_tower(cat_id: String, pos: Vector2) -> SimTower:
	var placement := can_place_tower_at(cat_id, pos)
	if not placement.get("valid", false):
		return null
	var cdata: Dictionary = cat_blueprints.get(cat_id, {})
	var base_cost = int(cdata.get("cost", 200))
	var price = economy.calculate_price(base_cost)
	
	if not economy.spend(price):
		return null
		
	unit_id_counter += 1
	var tower = SimTower.new()
	tower.setup(unit_id_counter, cdata, pos, price)
	towers.append(tower)
	_note_presentation("place", {"id": tower.instance_id, "cat": cat_id, "x": pos.x, "y": pos.y})
	
	replay.log_action(tick_counter, "place_tower", {"cat_id": cat_id, "pos": [pos.x, pos.y]})
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
	_note_presentation("place", {"id": -1, "cat": hero_id, "hero": true, "x": pos.x, "y": pos.y})
	replay.log_action(tick_counter, "place_hero", {"hero_id": hero_id, "pos": [pos.x, pos.y]})
	return hero

func upgrade_tower(tower: SimTower, path_key: String) -> bool:
	if not tower.can_upgrade(path_key):
		return false
	var next_tier = tower.tiers.get(path_key, 0)
	var paths = tower.cat_data.get("paths", {})
	var p_info = paths.get(path_key, {})
	var t_list: Array = p_info.get("tiers", [])
	if next_tier >= t_list.size():
		return false
		
	var base_cost = int(t_list[next_tier].get("cost", 100))
	var price = economy.calculate_price(base_cost)
	if not economy.spend(price):
		return false
		
	tower.apply_upgrade(path_key, price)
	_note_presentation("upgrade", {"id": tower.instance_id, "path": path_key, "tier": tower.tiers.get(path_key, 0)})
	replay.log_action(tick_counter, "upgrade_tower", {"tower_id": tower.instance_id, "path": path_key})
	return true

func sell_tower(tower: SimTower) -> int:
	if not economy.allow_selling:
		return 0
	var refund = economy.refund_sell(tower.total_spent)
	towers.erase(tower)
	replay.log_action(tick_counter, "sell_tower", {"tower_id": tower.instance_id})
	return refund

func lift_tower_tide(tower: SimTower) -> int:
	# Fairness Gate 6 / Spec 12: Lift refund is 100% of total spent
	var refund = tower.total_spent
	economy.kibble += refund
	towers.erase(tower)
	_note_presentation("tide_lift", {"id": tower.instance_id, "refund": refund})
	replay.log_action(tick_counter, "tide_lift", {"tower_id": tower.instance_id, "refund": refund})
	return refund

func start_next_round() -> bool:
	if round_in_progress or current_round >= max_rounds:
		return false
		
	current_round += 1
	round_in_progress = true
	pending_spawns.clear()
	
	var rkey = str(current_round)
	var rgroups: Array = round_data.get("rounds", {}).get(rkey, [])
	var map_modifier := _round_map_modifier(current_round)
	
	var cur_delay = 0.0
	var active_paths = get_active_paths_for_round(current_round)
	var spawn_seq_idx = 0
	for grp in rgroups:
		var configured_group: Dictionary = grp.duplicate(true)
		if not configured_group.has("rat"):
			if map_modifier.has("force_coat"):
				configured_group["coat"] = map_modifier["force_coat"]
			if map_modifier.get("shadow", false):
				configured_group["shadow"] = true
		var count = int(configured_group.get("count", 1))
		var spacing = float(configured_group.get("spacing", 0.5))
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
		u.tick(dt)
		var p_len = get_path_length(u.path_index)
		if u.s >= p_len:
			# Unit leaks!
			var leak_rbe = u.calculate_current_rbe()
			lives -= leak_rbe
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
	
	# Goldie income production
	for t in towers:
		if t.cat_id == "goldie":
			var income = 140
			if t.tiers.get("path_a", 0) >= 3:
				income = 400
			elif t.tiers.get("path_a", 0) >= 2:
				income = 280
			elif t.tiers.get("path_a", 0) >= 1:
				income = 200
			elif t.tiers.get("path_c", 0) >= 4:
				income = 300
			elif t.tiers.get("path_c", 0) >= 1:
				income = 160
			economy.kibble += income
	
	if hero != null:
		hero.add_round_xp(current_round)
		
	if current_round >= max_rounds:
		match_won = true

func _tick_tower_combat(tower: SimTower, dt: float) -> void:
	if tower.cat_id == "goldie":
		# Income generator, no attack
		return
		
	if tower.cat_id == "marlow":
		_tick_marlow_sonar(tower, dt)
	if tower.tick_cooldown(dt):
		var ignores_sight = (tower.cat_id == "biscuit" or tower.cat_id == "sable")
		var target = _find_target(tower.position, tower.range_radius, tower.see_shadow, tower.target_priority, tower.full_track_range, ignores_sight)
		if target != null:
			_fire_tower_attack(tower, target)

func _tick_hero_combat(dt: float) -> void:
	hero.attack_timer -= dt
	if hero.attack_timer <= 0.0:
		var target = _find_target(hero.position, hero.current_range, hero.see_shadow, SimConstants.TargetPriority.FIRST, false, false)
		if target != null:
			hero.attack_timer = hero.current_cooldown
			_note_presentation("fire", {"id": -1, "cat": hero.id, "x": hero.position.x, "y": hero.position.y, "target_s": target.s, "damage_type": hero.damage_type})
			var hit_res = target.hit(hero.current_damage, hero.damage_type)
			if hit_res.damage_dealt > 0:
				hero.damage_this_round += hit_res.damage_dealt
				hero.total_damage += hit_res.damage_dealt
			_process_hit_result(null, target, hit_res, hero.damage_type)

func _fire_tower_attack(tower: SimTower, target: SimUnit) -> void:
	var target_pos = get_point_on_path(target.s, target.path_index)
	_note_presentation("fire", {"id": tower.instance_id, "cat": tower.cat_id, "x": tower.position.x, "y": tower.position.y, "target_x": target_pos.x, "target_y": target_pos.y, "target_s": target.s, "damage_type": tower.damage_type})
	
	if tower.cat_id == "pudding":
		# Frostpaw area pulse
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
			float(tower.cat_data.get("base", {}).get("travel_time", 0.4))
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
			tower.projectile_speed,
			tower.tiers.get("path_c", 0) >= 3
		)
		projectiles.append(p)

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
		projectile.setup_linear(proj_id_counter, tower.instance_id, tower.position, target_pos, tower.damage, tower.damage_type, tower.pierce, tower.projectile_speed, _marlow_tier_value(tower, "dive") > 0.0)
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
			var hits = 0
			for u in units:
				if not u.is_alive or p.already_hit_unit_ids.has(u.id):
					continue
				var upos = get_point_on_path(u.s, u.path_index)
				if upos.distance_to(p.target_position) <= p.radius:
					p.already_hit_unit_ids[u.id] = true
					var hit_res = u.hit(p.damage, p.damage_type)
					var src_tower = _get_tower_by_id(p.source_cat_id)
					_process_hit_result(src_tower, u, hit_res)
					hits += 1
					if hits >= p.pierce_left:
						break
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
		_note_presentation("blocked", {"id": unit.id, "blocked_by": hit_res.blocked_by, "s": unit.s})
	elif hit_res.damage_dealt > 0:
		var visual_damage_type := src_tower.damage_type if src_tower != null else event_damage_type
		_note_presentation("hit", {"id": unit.id, "damage": hit_res.damage_dealt, "damage_type": visual_damage_type, "s": unit.s})
	if hit_res.damage_dealt > 0:
		var kibble_earned := economy.add_pop_damage(hit_res.hp_removed, current_round, hit_res.shell_bounty)
		_note_presentation("kibble", {"amount": kibble_earned, "s": unit.s})
		if src_tower != null:
			src_tower.add_feat_xp(float(hit_res.damage_dealt) * 0.4 + (3.0 if hit_res.coat_popped else 0.0))
	for coat in hit_res.get("popped_coats", []):
		_note_presentation("pop", {"id": unit.id, "coat": coat, "s": unit.s})
	_spawn_hit_children(unit.s, hit_res.children_to_spawn, unit.path_index, unit.path_id)

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
		if not u.can_be_targeted(has_night_eye):
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
	var price = economy.calculate_price(base_cost)
	var footprint = float(cdata.get("footprint_radius", 20.0))
	
	if not economy.can_afford(price):
		return {"valid": false, "reason": "Need %d Kibble" % price, "price": price}
	var surface := _placement_surface_ok(cdata.get("placement_mask", ["Land"]), pos)
	if not surface.get("valid", false):
		return {"valid": false, "reason": surface.get("reason", "Invalid surface"), "price": price}
		
	# Path clearance (track half-width is 15.0)
	var d_track = _distance_to_path(pos)
	if d_track < footprint + 16.0:
		return {"valid": false, "reason": "Cannot place on alley path", "price": price}
		
	# Sight blocker / prop clearance
	for blocker in sight_blockers:
		if blocker.grow(footprint).has_point(pos):
			return {"valid": false, "reason": "Blocked by obstacle", "price": price}
		
	# Tower collision clearance
	for t in towers:
		if pos.distance_to(t.position) < footprint + t.footprint_radius:
			return {"valid": false, "reason": "Overlaps another cat", "price": price}
			
	# Hero clearance
	if hero != null and pos.distance_to(hero.position) < footprint + 20.0:
		return {"valid": false, "reason": "Overlaps hero", "price": price}
		
	return {"valid": true, "reason": "OK", "price": price, "footprint": footprint}

func can_place_hero_at(hero_id: String, pos: Vector2) -> Dictionary:
	if hero != null:
		return {"valid": false, "reason": "Hero already deployed"}
	var hdata: Dictionary = hero_blueprints.get(hero_id, {})
	var cost = int(hdata.get("place_cost", 600))
	var price = economy.calculate_price(cost)
	var footprint = 20.0
	
	if not economy.can_afford(price):
		return {"valid": false, "reason": "Need %d Kibble" % price, "price": price}
	var surface := _placement_surface_ok(hdata.get("placement_mask", ["Land"]), pos)
	if not surface.get("valid", false):
		return {"valid": false, "reason": surface.get("reason", "Invalid surface"), "price": price}
		
	var d_track = _distance_to_path(pos)
	if d_track < footprint + 16.0:
		return {"valid": false, "reason": "Cannot place on alley path", "price": price}
		
	# Sight blocker / prop clearance
	for blocker in sight_blockers:
		if blocker.grow(footprint).has_point(pos):
			return {"valid": false, "reason": "Blocked by obstacle", "price": price}
		
	for t in towers:
		if pos.distance_to(t.position) < footprint + t.footprint_radius:
			return {"valid": false, "reason": "Overlaps another cat", "price": price}
			
	return {"valid": true, "reason": "OK", "price": price, "footprint": footprint}

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
			# Spool Barrage: for next few seconds fast seeking needles
			for i in range(5):
				proj_id_counter += 1
				var p = SimProjectile.new()
				p.setup_linear(
					proj_id_counter,
					-1,
					hero.position,
					hero.position + Vector2(randf_range(-50, 50), -100),
					3,
					SimConstants.DamageType.BITE,
					5,
					500.0,
					true
				)
				projectiles.append(p)
	_note_presentation("ability", {"id": -1, "hero": hero.id, "slot": slot, "x": hero.position.x, "y": hero.position.y})
	replay.log_action(tick_counter, "hero_ability", {"slot": slot})
	return true


