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

var pending_spawns: Array[Dictionary] = [] # {"time": 0.5, "unit_config": {...}}
var round_in_progress: bool = false
var unit_id_counter: int = 0
var proj_id_counter: int = 0

# Loaded data repositories
var mice_data: Dictionary = {}
var rats_data: Dictionary = {}
var cat_blueprints: Dictionary = {}
var hero_blueprints: Dictionary = {}
var round_data: Dictionary = {}

func setup(
	p_mode: int,
	p_seed: int,
	p_mice_data: Dictionary,
	p_rats_data: Dictionary,
	p_cat_blueprints: Dictionary,
	p_hero_blueprints: Dictionary,
	p_round_data: Dictionary,
	start_kibble_bonus: int = 0
) -> void:
	mode = p_mode
	mice_data = p_mice_data
	rats_data = p_rats_data
	cat_blueprints = p_cat_blueprints
	hero_blueprints = p_hero_blueprints
	round_data = p_round_data
	
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

func get_point_on_path(s: float) -> Vector2:
	# Standard Sunny Gutter 1200 polyline
	var clamped_s = clampf(s, 0.0, path_length)
	if clamped_s <= 600.0:
		return Vector2(40.0 + clamped_s, 100.0)
	elif clamped_s <= 900.0:
		return Vector2(640.0, 100.0 + (clamped_s - 600.0))
	else:
		return Vector2(640.0 - (clamped_s - 900.0), 400.0)

func place_tower(cat_id: String, pos: Vector2) -> SimTower:
	var cdata: Dictionary = cat_blueprints.get(cat_id, {})
	var base_cost = int(cdata.get("cost", 200))
	var price = economy.calculate_price(base_cost)
	
	if not economy.spend(price):
		return null
		
	unit_id_counter += 1
	var tower = SimTower.new()
	tower.setup(unit_id_counter, cdata, pos, price)
	towers.append(tower)
	
	replay.log_action(tick_counter, "place_tower", {"cat_id": cat_id, "pos": [pos.x, pos.y]})
	return tower

func place_hero(hero_id: String, pos: Vector2) -> SimHero:
	if hero != null:
		return null
	var hdata: Dictionary = hero_blueprints.get(hero_id, {})
	var cost = int(hdata.get("place_cost", 600))
	var price = economy.calculate_price(cost)
	
	if not economy.spend(price):
		return null
		
	hero = SimHero.new()
	hero.setup(hdata, pos, 1)
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
	replay.log_action(tick_counter, "upgrade_tower", {"tower_id": tower.instance_id, "path": path_key})
	return true

func sell_tower(tower: SimTower) -> int:
	if not economy.allow_selling:
		return 0
	var refund = economy.refund_sell(tower.total_spent)
	towers.erase(tower)
	replay.log_action(tick_counter, "sell_tower", {"tower_id": tower.instance_id})
	return refund

func start_next_round() -> bool:
	if round_in_progress or current_round >= max_rounds:
		return false
		
	current_round += 1
	round_in_progress = true
	pending_spawns.clear()
	
	var rkey = str(current_round)
	var rgroups: Array = round_data.get("rounds", {}).get(rkey, [])
	
	var cur_delay = 0.0
	for grp in rgroups:
		var count = int(grp.get("count", 1))
		var spacing = float(grp.get("spacing", 0.5))
		for _i in range(count):
			var spawn_item = grp.duplicate()
			spawn_item.erase("count")
			spawn_item.erase("spacing")
			pending_spawns.append({
				"delay": cur_delay,
				"config": spawn_item
			})
			cur_delay += spacing
			
	replay.log_action(tick_counter, "start_round", {"round": current_round})
	return true

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
		
	u.s = path_s
	units.append(u)
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
		if u.s >= path_length:
			# Unit leaks!
			var leak_rbe = u.calculate_current_rbe()
			lives -= leak_rbe
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
		
	if tower.tick_cooldown(dt):
		var target = _find_target(tower.position, tower.range_radius, tower.see_shadow, tower.target_priority, tower.full_track_range)
		if target != null:
			_fire_tower_attack(tower, target)

func _tick_hero_combat(dt: float) -> void:
	hero.attack_timer -= dt
	if hero.attack_timer <= 0.0:
		var target = _find_target(hero.position, hero.current_range, hero.see_shadow, SimConstants.TargetPriority.FIRST, false)
		if target != null:
			hero.attack_timer = hero.current_cooldown
			var hit_res = target.hit(hero.current_damage, hero.damage_type)
			if hit_res.damage_dealt > 0:
				hero.damage_this_round += hit_res.damage_dealt
				hero.total_damage += hit_res.damage_dealt
				economy.add_pop_damage(hit_res.hp_removed, current_round, hit_res.shell_bounty)
				_spawn_hit_children(target.s, hit_res.children_to_spawn)

func _fire_tower_attack(tower: SimTower, target: SimUnit) -> void:
	var target_pos = get_point_on_path(target.s)
	
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
			var upos = get_point_on_path(u.s)
			if upos.distance_to(tower.position) <= tower.range_radius:
				if u.is_rat:
					u.status.apply_freeze(0.3 if u.unit_type != "matriarch" else 0.0)
				else:
					u.status.apply_freeze(freeze_time)
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
			var upos = get_point_on_path(u.s)
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
				var upos = get_point_on_path(u.s)
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
			# Collision check with units
			for u in units:
				if not u.is_alive or p.already_hit_unit_ids.has(u.id):
					continue
				var upos = get_point_on_path(u.s)
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

func _process_hit_result(src_tower: SimTower, unit: SimUnit, hit_res: Dictionary) -> void:
	if hit_res.damage_dealt > 0:
		economy.add_pop_damage(hit_res.hp_removed, current_round, hit_res.shell_bounty)
		if src_tower != null:
			src_tower.add_feat_xp(float(hit_res.damage_dealt) * 0.4 + (3.0 if hit_res.coat_popped else 0.0))
	_spawn_hit_children(unit.s, hit_res.children_to_spawn)

func _spawn_hit_children(path_s: float, children_configs: Array) -> void:
	for ch in children_configs:
		spawn_unit(ch, path_s)

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
	full_track: bool
) -> SimUnit:
	var best_unit: SimUnit = null
	var best_score: float = -999999.0
	
	for u in units:
		if not u.is_alive:
			continue
		if not u.can_be_targeted(has_night_eye):
			continue
		var upos = get_point_on_path(u.s)
		if not full_track and upos.distance_to(origin) > range_r:
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
	var p0 = Vector2(40.0, 100.0)
	var p1 = Vector2(640.0, 100.0)
	var p2 = Vector2(640.0, 400.0)
	var p3 = Vector2(340.0, 400.0)
	var d1 = _distance_to_segment(pos, p0, p1)
	var d2 = _distance_to_segment(pos, p1, p2)
	var d3 = _distance_to_segment(pos, p2, p3)
	return minf(d1, minf(d2, d3))

func can_place_tower_at(cat_id: String, pos: Vector2) -> Dictionary:
	var cdata: Dictionary = cat_blueprints.get(cat_id, {})
	var base_cost = int(cdata.get("cost", 200))
	var price = economy.calculate_price(base_cost)
	var footprint = float(cdata.get("footprint_radius", 20.0))
	
	if not economy.can_afford(price):
		return {"valid": false, "reason": "Need %d Kibble" % price, "price": price}
		
	# Path clearance (track half-width is 15.0)
	var d_track = _distance_to_path(pos)
	if d_track < footprint + 16.0:
		return {"valid": false, "reason": "Cannot place on alley path", "price": price}
		
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
		
	var d_track = _distance_to_path(pos)
	if d_track < footprint + 16.0:
		return {"valid": false, "reason": "Cannot place on alley path", "price": price}
		
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
	replay.log_action(tick_counter, "hero_ability", {"slot": slot})
	return true


