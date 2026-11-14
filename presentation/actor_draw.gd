class_name ActorDraw
extends RefCounted

const CAT_COLORS := {"pip": Color("e67d22"), "nibs": Color("343c47"), "pudding": Color("d9ecf7"), "biscuit": Color("d0692c"), "sable": Color("252b31"), "nim": Color("9a55b5"), "goldie": Color("f2a23a"), "miso": Color("94705d"), "mittens": Color("5c6b7d")}
const COAT_COLORS := {"rust": Color("b84124"), "slate": Color("71808f"), "moss": Color("4a7d38"), "grain": Color("d9ad36"), "sugar": Color("f39aac"), "soot": Color("373335"), "frost": Color("64c5d9"), "ink": Color("42245f"), "iron": Color("91989f"), "marble": Color("599eaf"), "prism": Color("d866d7"), "porcelain": Color("f5f3e9")}
var time := 0.0
var attacks: Dictionary = {}
var child_scales: Dictionary = {}

func advance(delta: float) -> void:
	time += delta
	for key in attacks.keys():
		attacks[key].age += delta
		if attacks[key].age > 0.38:
			attacks.erase(key)
	for key in child_scales.keys():
		child_scales[key] -= delta
		if child_scales[key] <= 0.0:
			child_scales.erase(key)

func note(event: Dictionary) -> void:
	if event.get("type", "") == "fire":
		attacks[int(event.get("id", -1))] = {"age": 0.0, "target_x": float(event.get("target_x", 99999.0))}
	elif event.get("type", "") == "child":
		child_scales[int(event.get("id", -1))] = 0.27

func draw_actors(canvas: CanvasItem, sim, displayed_s: Dictionary, selected_tower, selected_hero: bool, cats: Dictionary, mice: Dictionary, rats: Dictionary) -> void:
	for tower in sim.towers:
		_draw_tower(canvas, tower, tower == selected_tower, cats)
	if sim.hero != null:
		_draw_hero(canvas, sim.hero, selected_hero, cats)
	for unit in sim.units:
		if unit.is_alive:
			var s := float(displayed_s.get(unit.id, unit.s))
			var pos: Vector2 = sim.get_point_on_path(s, unit.path_index)
			if unit.is_rat:
				_draw_rat(canvas, pos, unit, rats)
			else:
				_draw_mouse(canvas, pos, unit, mice)
	_draw_projectiles(canvas, sim)

func _draw_tower(canvas: CanvasItem, tower, selected: bool, cats: Dictionary) -> void:
	if selected:
		canvas.draw_circle(tower.position, tower.range_radius, Color(CAT_COLORS.get(tower.cat_id, Color.WHITE), 0.14))
		canvas.draw_arc(tower.position, tower.range_radius, 0, TAU, 48, Color("ffd763"), 2.0)
	_draw_aura(canvas, tower)
	var attack: Dictionary = attacks.get(tower.instance_id, {})
	var facing_left: bool = not attack.is_empty() and float(attack.get("target_x", 99999.0)) < tower.position.x
	var frame := _frame_for(tower.instance_id, attack)
	_draw_sprite(canvas, cats.get(tower.cat_id), tower.position + Vector2(0, sin(time * 3.0 + tower.position.x) * 1.5), tower.footprint_radius * 3.3, facing_left, frame)
	if cats.get(tower.cat_id) == null:
		canvas.draw_circle(tower.position, tower.footprint_radius, CAT_COLORS.get(tower.cat_id, Color("d88b42")))
	_draw_ornament(canvas, tower)
	if tower.feat_rank > 0:
		canvas.draw_string(ThemeDB.fallback_font, tower.position + Vector2(-16, -38), "★".repeat(tower.feat_rank), HORIZONTAL_ALIGNMENT_CENTER, 32, 12, Color("ffda60"))
	if tower.cat_id == "nim" and _tier_flag(tower, "is_beam") and not attack.is_empty():
		canvas.draw_line(tower.position, Vector2(float(attack.target_x), tower.position.y), Color(0.66, 0.35, 0.94, 0.5), 3.0)

func _draw_hero(canvas: CanvasItem, hero, selected: bool, cats: Dictionary) -> void:
	if selected:
		canvas.draw_arc(hero.position, hero.current_range, 0, TAU, 48, Color("7bc8ff"), 2.0)
	var attack: Dictionary = attacks.get(-1, {})
	_draw_sprite(canvas, cats.get(hero.id), hero.position, 72.0, not attack.is_empty() and attack.target_x < hero.position.x, _frame_for(-1, attack))
	if cats.get(hero.id) == null:
		canvas.draw_circle(hero.position, 22.0, CAT_COLORS.get(hero.id, Color("728298")))
	canvas.draw_string(ThemeDB.fallback_font, hero.position + Vector2(-17, -43), "LV %d" % hero.level, HORIZONTAL_ALIGNMENT_CENTER, 34, 12, Color("ffe275"))
	_draw_cooldown_ring(canvas, hero.position + Vector2(-18, 26), hero.ability_1_cooldown_left, hero.hero_data.get("active_abilities", {}).get("ability_1", {}).get("cooldown", 1.0))
	_draw_cooldown_ring(canvas, hero.position + Vector2(18, 26), hero.ability_2_cooldown_left, hero.hero_data.get("active_abilities", {}).get("ability_2", {}).get("cooldown", 1.0))

func _draw_mouse(canvas: CanvasItem, pos: Vector2, unit, mice: Dictionary) -> void:
	var scale := 0.4 + 0.6 * (1.0 - float(child_scales.get(unit.id, 0.0)) / 0.27)
	var height := (34.0 if unit.unit_type == "porcelain" else 28.0) * scale
	_draw_shadow(canvas, pos + Vector2(0, 6), 10.0 * scale)
	_draw_sprite(canvas, mice.get(unit.unit_type), pos, height, false, int(time * 7.0) % 4, 0.45 if unit.is_shadow else 1.0)
	if mice.get(unit.unit_type) == null:
		canvas.draw_circle(pos, 11.0 * scale, COAT_COLORS.get(unit.unit_type, Color("d85b4a")))
	if unit.is_plated:
		canvas.draw_arc(pos, 16 * scale, 0, TAU, 20, Color("e8edf1"), 2.0)
	if unit.is_shadow:
		canvas.draw_string(ThemeDB.fallback_font, pos + Vector2(-6, -19), "✦", HORIZONTAL_ALIGNMENT_CENTER, 12, 12, Color("d994ff"))
	_draw_status(canvas, pos, unit.status)

func _draw_rat(canvas: CanvasItem, pos: Vector2, unit, rats: Dictionary) -> void:
	var heights := {"burrow": 70.0, "bristle": 82.0, "monarch": 96.0, "dusk": 78.0, "matriarch": 112.0}
	var height: float = heights.get(unit.unit_type, 70.0)
	_draw_shadow(canvas, pos + Vector2(0, 8), height * 0.25)
	_draw_sprite(canvas, rats.get(unit.unit_type), pos, height, false, int(time * 5.0) % 4)
	if rats.get(unit.unit_type) == null:
		canvas.draw_circle(pos, height * 0.32, Color("795044"))
	if unit.is_plated:
		canvas.draw_arc(pos, height * 0.37, 0, TAU, 28, Color("e1e6ed"), 3.0)
	var bar := Rect2(pos + Vector2(-32, -height * 0.72), Vector2(64, 7))
	canvas.draw_rect(bar, Color("2d2b2b"))
	var ratio := clampf(float(unit.body_hp) / maxf(1.0, float(unit.max_body_hp)), 0.0, 1.0)
	canvas.draw_rect(Rect2(bar.position, Vector2(bar.size.x * ratio, bar.size.y)), Color("4fd676").lerp(Color("db5348"), 1.0 - ratio))
	_draw_status(canvas, pos, unit.status)

func _draw_projectiles(canvas: CanvasItem, sim) -> void:
	var colors := [Color("f0af3a"), Color("d5564e"), Color("f18735"), Color("a673e5"), Color("77bc59"), Color("38264b"), Color.WHITE]
	for projectile in sim.projectiles:
		if projectile.is_active:
			var color: Color = colors[clampi(projectile.damage_type, 0, colors.size() - 1)]
			if projectile.is_explosion:
				canvas.draw_arc(projectile.target_position, maxf(12, projectile.radius * 0.45), 0, TAU, 20, Color(color, 0.7), 2.0)
			else:
				var direction: Vector2 = (projectile.target_position - projectile.position).normalized()
				canvas.draw_line(projectile.position - direction * 11, projectile.position, color, 3.0)
				canvas.draw_circle(projectile.position, 3.3, color)

func _draw_sprite(canvas: CanvasItem, texture: Texture2D, pos: Vector2, height: float, flip: bool, frame: int, alpha: float = 1.0) -> void:
	if texture == null:
		return
	var sheet := texture.get_width() >= 1280 and texture.get_height() >= 128
	var aspect := 1.0 if sheet else float(texture.get_width()) / float(texture.get_height())
	var size := Vector2(height * aspect, height)
	canvas.draw_set_transform(pos, 0.0, Vector2(-1 if flip else 1, 1))
	var dest := Rect2(Vector2(-size.x * 0.5, -size.y * 0.78), size)
	if sheet:
		canvas.draw_texture_rect_region(texture, dest, Rect2((frame % 10) * 128, 0, 128, 128), Color(1, 1, 1, alpha))
	else:
		canvas.draw_texture_rect(texture, dest, false, Color(1, 1, 1, alpha))
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_shadow(canvas: CanvasItem, pos: Vector2, radius: float) -> void:
	canvas.draw_set_transform(pos, 0.0, Vector2(1.0, 0.38))
	canvas.draw_circle(Vector2.ZERO, radius, Color(0.05, 0.07, 0.04, 0.28))
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_status(canvas: CanvasItem, pos: Vector2, status) -> void:
	if status.freeze_time > 0:
		canvas.draw_arc(pos, 15, 0, TAU, 16, Color("a9eaff"), 2.0)
	if status.burn_time > 0:
		canvas.draw_circle(pos + Vector2(0, -15), 4, Color("f07b37"))
	if status.mark_time > 0:
		canvas.draw_arc(pos, 11, 0, TAU, 12, Color("f5d557"), 1.5)
	if status.hex_time > 0:
		canvas.draw_string(ThemeDB.fallback_font, pos + Vector2(-5, -15), "✧", HORIZONTAL_ALIGNMENT_CENTER, 10, 13, Color("bd78f0"))
	if status.stun_time > 0:
		canvas.draw_string(ThemeDB.fallback_font, pos + Vector2(-8, -22), "✦ ✦", HORIZONTAL_ALIGNMENT_CENTER, 16, 10, Color("fff2a2"))

func _draw_ornament(canvas: CanvasItem, tower) -> void:
	var top := maxi(tower.tiers.path_a, maxi(tower.tiers.path_b, tower.tiers.path_c))
	if top <= 0:
		return
	var color := Color("ffd76a") if top >= 5 else Color("c9eff7") if top >= 3 else Color("e9aa65")
	canvas.draw_arc(tower.position + Vector2(0, 5), tower.footprint_radius + 5, PI * 1.08, PI * 1.92, 12, color, 2.5)
	for i in range(top):
		canvas.draw_circle(tower.position + Vector2(-8 + i * 4, 20), 1.6, color)
	if top >= 5:
		canvas.draw_arc(tower.position, tower.footprint_radius + 10, 0, TAU, 24, Color(color, 0.45), 1.5)

func _draw_aura(canvas: CanvasItem, tower) -> void:
	if tower.cat_id == "miso":
		var radius := _tier_value(tower, "aura_radius", 110.0)
		canvas.draw_arc(tower.position, radius, 0, TAU, 40, Color(0.54, 0.85, 0.75, 0.28), 1.5)
	if tower.cat_id == "pudding" and _tier_flag(tower, "permanent_zone_radius"):
		canvas.draw_circle(tower.position, _tier_value(tower, "permanent_zone_radius", 80.0), Color(0.55, 0.83, 1.0, 0.12))

func _draw_cooldown_ring(canvas: CanvasItem, pos: Vector2, left: float, total: float) -> void:
	canvas.draw_circle(pos, 9, Color("201812"))
	var progress := clampf(1.0 - left / maxf(0.1, float(total)), 0.0, 1.0)
	canvas.draw_arc(pos, 9, -PI * 0.5, -PI * 0.5 + TAU * progress, 14, Color("82cdf4"), 2.0)

func _frame_for(id: int, attack: Dictionary) -> int:
	if attack.is_empty():
		return int(time * 4.0) % 4
	return 4 + mini(5, int(float(attack.age) / 0.38 * 6.0))

func _tier_value(tower, key: String, fallback: float) -> float:
	var value := fallback
	var paths: Dictionary = tower.cat_data.get("paths", {})
	for path in paths.keys():
		var path_data: Dictionary = paths.get(path, {})
		var tiers: Array = path_data.get("tiers", [])
		for index in range(mini(int(tower.tiers.get(path, 0)), tiers.size())):
			if tiers[index].has(key): value = float(tiers[index][key])
	return value

func _tier_flag(tower, key: String) -> bool:
	return _tier_value(tower, key, 0.0) > 0.0
