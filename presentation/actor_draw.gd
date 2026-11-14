class_name ActorDraw
extends RefCounted

const CAT_COLORS := {
	"pip": Color("e67d22"), "nibs": Color("343c47"), "pudding": Color("d9ecf7"),
	"biscuit": Color("d0692c"), "sable": Color("252b31"), "nim": Color("9a55b5"),
	"goldie": Color("f2a23a"), "miso": Color("94705d"), "mittens": Color("5c6b7d"),
	"duchess": Color("9b59b6"), "baron": Color("c0392b"), "pebble": Color("27ae60")
}
const COAT_COLORS := {
	"rust": Color("b84124"), "slate": Color("71808f"), "moss": Color("4a7d38"),
	"grain": Color("d9ad36"), "sugar": Color("f39aac"), "soot": Color("373335"),
	"frost": Color("64c5d9"), "ink": Color("42245f"), "iron": Color("91989f"),
	"marble": Color("599eaf"), "prism": Color("d866d7"), "porcelain": Color("f5f3e9")
}
var time := 0.0
var attacks: Dictionary = {}
var child_scales: Dictionary = {}
var between_rounds_timer := 0.0
var was_in_round := false

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
		attacks[int(event.get("id", -1))] = {
			"age": 0.0,
			"target_x": float(event.get("target_x", 99999.0)),
			"target_y": float(event.get("target_y", 0.0))
		}
	elif event.get("type", "") == "child":
		child_scales[int(event.get("id", -1))] = 0.27

func draw_actors(canvas: CanvasItem, sim, displayed_s: Dictionary, selected_tower, selected_hero: bool, cats: Dictionary, mice: Dictionary, rats: Dictionary) -> void:
	var round_in_progress: bool = bool(sim.get("round_in_progress"))
	if not round_in_progress:
		between_rounds_timer += 0.016
	else:
		between_rounds_timer = 0.0

	for tower in sim.towers:
		_draw_tower(canvas, tower, tower == selected_tower, cats, round_in_progress)
	if sim.hero != null:
		_draw_hero(canvas, sim.hero, selected_hero, cats)
	for unit in sim.units:
		if unit.is_alive:
			var s := float(displayed_s.get(unit.id, unit.s))
			var pos: Vector2 = sim.get_point_on_path(s, unit.path_index)
			var next_pos: Vector2 = sim.get_point_on_path(s + 3.0, unit.path_index)
			var flip: bool = (next_pos.x - pos.x) < -0.05
			if unit.is_rat:
				_draw_rat(canvas, pos, unit, rats, flip)
			else:
				_draw_mouse(canvas, pos, unit, mice, flip)
	_draw_projectiles(canvas, sim)

func _draw_tower(canvas: CanvasItem, tower, selected: bool, cats: Dictionary, in_round: bool) -> void:
	if selected:
		canvas.draw_circle(tower.position, tower.range_radius, Color(CAT_COLORS.get(tower.cat_id, Color.WHITE), 0.14))
		canvas.draw_arc(tower.position, tower.range_radius, 0, TAU, 48, Color("ffd763"), 2.0)
	_draw_aura(canvas, tower)
	var attack: Dictionary = attacks.get(tower.instance_id, {})
	var facing_left: bool = not attack.is_empty() and float(attack.get("target_x", 99999.0)) < tower.position.x
	var frame := _frame_for(tower.instance_id, attack)
	var bob := sin(time * 3.0 + tower.position.x) * 1.5 if in_round else sin(time * 1.8 + tower.position.x) * 0.8
	_draw_sprite(canvas, cats.get(tower.cat_id), tower.position + Vector2(0, bob), tower.footprint_radius * 3.3, facing_left, frame)
	if cats.get(tower.cat_id) == null:
		canvas.draw_circle(tower.position, tower.footprint_radius, CAT_COLORS.get(tower.cat_id, Color("d88b42")))
	_draw_ornament(canvas, tower)

	# Co-op Player indicator bead
	var owner_id: int = int(tower.owner_id) if "owner_id" in tower else 1
	var collar_col = Color(0.2, 0.85, 0.95, 0.9) if owner_id == 1 else Color(1.0, 0.55, 0.15, 0.9)
	canvas.draw_circle(tower.position + Vector2(0, 14), 3.5, collar_col)

	# Comedic between-round idle actions when peaceful
	if not in_round and attack.is_empty():
		_draw_between_round_comedy(canvas, tower)

	if tower.feat_rank > 0:
		canvas.draw_string(ThemeDB.fallback_font, tower.position + Vector2(-16, -38), "★".repeat(tower.feat_rank), HORIZONTAL_ALIGNMENT_CENTER, 32, 12, Color("ffda60"))
	if not attack.is_empty():
		var target_pos := Vector2(float(attack.get("target_x", tower.position.x)), float(attack.get("target_y", tower.position.y)))
		if tower.cat_id == "nim":
			canvas.draw_line(tower.position, target_pos, Color(0.75, 0.45, 1.0, 0.45), 5.0)
			canvas.draw_line(tower.position, target_pos, Color(1.0, 1.0, 1.0, 0.9), 2.0)
		elif tower.cat_id == "sable":
			var t_att := clampf(float(attack.age) / 0.38, 0.0, 1.0)
			canvas.draw_line(tower.position, target_pos, Color(1.0, 0.90, 0.45, 1.0 - t_att), 2.5)

func _draw_between_round_comedy(canvas: CanvasItem, tower) -> void:
	var phase := fmod(time + tower.position.x * 0.05, 5.0)
	match tower.cat_id:
		"pip":
			# Notices a stray thread on fur, nonchalantly picks it off
			if phase >= 1.5 and phase <= 3.2:
				var t_pip := (phase - 1.5) / 1.7
				var thread_p: Vector2 = tower.position + Vector2(8, -14 - sin(t_pip * PI) * 6.0)
				canvas.draw_arc(thread_p, 4.0, 0, PI * 1.4, 8, Color("ffe4b5"), 1.5)
				if phase > 2.8:
					canvas.draw_circle(thread_p + Vector2(4, -4), 1.5, Color(1, 1, 1, 0.8))
		"nibs":
			# After round: fur bristling, then quick grooming lick
			if between_rounds_timer < 3.5:
				var groom_p: Vector2 = tower.position + Vector2(0, -28)
				canvas.draw_arc(groom_p, 6.0, PI * 0.2, PI * 1.1, 8, Color("c0c8d8"), 1.5)
		"pudding":
			# Drowsy snooze: gentle zZz floating up from cozy loaf
			var z_t := fmod(time * 0.8 + tower.position.x * 0.02, 2.0) / 2.0
			var z_pos: Vector2 = tower.position + Vector2(10 + z_t * 6.0, -22 - z_t * 22.0)
			canvas.draw_string(ThemeDB.fallback_font, z_pos, "z", HORIZONTAL_ALIGNMENT_CENTER, 12, 11, Color(0.75, 0.90, 1.0, 1.0 - z_t))
		"biscuit":
			# Inspects mortar basket like a professional cannon
			if phase >= 2.0 and phase <= 3.8:
				var pointer_pos: Vector2 = tower.position + Vector2(14, -12)
				canvas.draw_line(pointer_pos, pointer_pos + Vector2(8, 6), Color("d5c09a"), 2.0)
				canvas.draw_circle(pointer_pos + Vector2(8, 6), 2.0, Color("f5e0b8"))
		"sable":
			# Pedantically polishes rifle scope with velvet cloth
			if phase >= 1.0 and phase <= 3.5:
				var cloth_p: Vector2 = tower.position + Vector2(6, -20)
				canvas.draw_circle(cloth_p + Vector2(sin(time * 8.0) * 3.0, 0), 2.5, Color(0.85, 0.25, 0.35, 0.8))
		"nim":
			# Tries to catch runaway spark, sneezes (*achoo!*)
			if phase >= 2.0 and phase <= 3.6:
				var spark_p: Vector2 = tower.position + Vector2(14 + sin(time * 10.0) * 4.0, -28)
				canvas.draw_circle(spark_p, 2.0, Color(0.85, 0.65, 1.0, 0.9))
				if phase > 3.2:
					canvas.draw_string(ThemeDB.fallback_font, tower.position + Vector2(8, -38), "achoo!", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.95, 0.85, 1.0, 0.85))
		"goldie":
			# Counts fish in wooden crate, shoos a seagull away
			if phase >= 1.5 and phase <= 3.8:
				var crate_p: Vector2 = tower.position + Vector2(12, -4)
				canvas.draw_rect(Rect2(crate_p.x - 5, crate_p.y - 4, 10, 8), Color(0.65, 0.45, 0.25), true)
				canvas.draw_circle(crate_p + Vector2(0, -6), 1.8, Color(0.85, 0.90, 0.95))
		"miso":
			# Wipes tea cup with towel, friendly bow
			if phase >= 1.5 and phase <= 3.5:
				var cup_p: Vector2 = tower.position + Vector2(10, -10)
				canvas.draw_circle(cup_p, 3.0, Color(0.95, 0.92, 0.85))
				canvas.draw_arc(cup_p, 4.0, 0, PI, 6, Color(1, 1, 1, 0.7), 1.5)

func _draw_hero(canvas: CanvasItem, hero, selected: bool, cats: Dictionary) -> void:
	if selected:
		canvas.draw_arc(hero.position, hero.current_range, 0, TAU, 48, Color("7bc8ff"), 2.0)
	var attack: Dictionary = attacks.get(-1, {})
	var tex: Texture2D = cats.get(hero.id)
	if tex != null:
		_draw_sprite(canvas, tex, hero.position, 72.0, not attack.is_empty() and attack.target_x < hero.position.x, _frame_for(-1, attack))
	else:
		# Distinct geometric fallback with hero-specific color & initial (NEVER masquerade as Mittens)
		var hero_col: Color = CAT_COLORS.get(hero.id, Color("728298"))
		canvas.draw_circle(hero.position, 24.0, hero_col)
		canvas.draw_arc(hero.position, 24.0, 0, TAU, 28, Color("ffd763"), 2.0)
		var initial: String = hero.id.substr(0, 1).to_upper()
		canvas.draw_string(ThemeDB.fallback_font, hero.position + Vector2(-6, 5), initial, HORIZONTAL_ALIGNMENT_CENTER, 12, 14, Color.WHITE)

	canvas.draw_string(ThemeDB.fallback_font, hero.position + Vector2(-17, -43), "LV %d" % hero.level, HORIZONTAL_ALIGNMENT_CENTER, 34, 12, Color("ffe275"))
	_draw_cooldown_ring(canvas, hero.position + Vector2(-18, 26), hero.ability_1_cooldown_left, hero.hero_data.get("active_abilities", {}).get("ability_1", {}).get("cooldown", 1.0))
	_draw_cooldown_ring(canvas, hero.position + Vector2(18, 26), hero.ability_2_cooldown_left, hero.hero_data.get("active_abilities", {}).get("ability_2", {}).get("cooldown", 1.0))

func _draw_mouse(canvas: CanvasItem, pos: Vector2, unit, mice: Dictionary, flip: bool) -> void:
	var scale := 0.4 + 0.6 * (1.0 - float(child_scales.get(unit.id, 0.0)) / 0.27)
	var height := (34.0 if unit.unit_type == "porcelain" else 28.0) * scale
	_draw_shadow(canvas, pos + Vector2(0, 6), 10.0 * scale)
	_draw_sprite(canvas, mice.get(unit.unit_type), pos, height, flip, int(time * 7.0) % 4, 0.45 if unit.is_shadow else 1.0)
	if mice.get(unit.unit_type) == null:
		canvas.draw_circle(pos, 11.0 * scale, COAT_COLORS.get(unit.unit_type, Color("d85b4a")))
	if unit.is_plated:
		canvas.draw_arc(pos, 16 * scale, 0, TAU, 20, Color("e8edf1"), 2.0)
	if unit.is_shadow:
		canvas.draw_string(ThemeDB.fallback_font, pos + Vector2(-6, -19), "✦", HORIZONTAL_ALIGNMENT_CENTER, 12, 12, Color("d994ff"))

	# Porcelain cracks reflecting shell damage & health pips
	if unit.unit_type == "porcelain":
		var cur_lhp := int(unit.get("layer_hp", 1))
		var max_lhp := int(unit.get("max_layer_hp", 10))
		if cur_lhp < max_lhp:
			# Kintsugi crack lines across ceramic shell
			var dmg_frac := 1.0 - float(cur_lhp) / maxf(1.0, float(max_lhp))
			canvas.draw_line(pos + Vector2(-6, -10), pos + Vector2(-1, -4), Color(0.25, 0.22, 0.20, 0.8), 1.5)
			if dmg_frac > 0.4:
				canvas.draw_line(pos + Vector2(-1, -4), pos + Vector2(5, -7), Color(0.25, 0.22, 0.20, 0.8), 1.2)
			if dmg_frac > 0.7:
				canvas.draw_line(pos + Vector2(-1, -4), pos + Vector2(2, 2), Color(0.85, 0.70, 0.25, 0.9), 1.5)
	elif unit.unit_type == "ink":
		# Soft mystic purple sigil
		canvas.draw_arc(pos + Vector2(0, -12), 4.0, 0, TAU, 8, Color(0.65, 0.35, 0.95, 0.6), 1.2)
	elif unit.unit_type == "prism":
		# Prismatic rainbow glint
		var prism_ang := time * 4.0
		canvas.draw_circle(pos + Vector2(cos(prism_ang) * 6.0, -8), 1.5, Color(1, 0.9, 0.4, 0.8))
	elif unit.unit_type == "marble":
		# Stone slab rim
		canvas.draw_line(pos + Vector2(-6, -4), pos + Vector2(6, -4), Color(0.45, 0.52, 0.58, 0.7), 2.0)

	_draw_status(canvas, pos, unit.status, unit.unit_type)

func _draw_rat(canvas: CanvasItem, pos: Vector2, unit, rats: Dictionary, flip: bool) -> void:
	var heights := {"burrow": 70.0, "bristle": 82.0, "monarch": 96.0, "dusk": 78.0, "matriarch": 112.0}
	var height: float = heights.get(unit.unit_type, 70.0)
	_draw_shadow(canvas, pos + Vector2(0, 8), height * 0.25)
	_draw_sprite(canvas, rats.get(unit.unit_type), pos, height, flip, int(time * 5.0) % 4)
	if rats.get(unit.unit_type) == null:
		canvas.draw_circle(pos, height * 0.32, Color("795044"))
	if unit.is_plated:
		canvas.draw_arc(pos, height * 0.37, 0, TAU, 28, Color("e1e6ed"), 3.0)

	var ratio := clampf(float(unit.body_hp) / maxf(1.0, float(unit.max_body_hp)), 0.0, 1.0)

	# Rat damage states at 75%, 50%, 25% health: increasingly disheveled, but keeps character!
	match unit.unit_type:
		"burrow":
			if ratio <= 0.75:
				canvas.draw_line(pos + Vector2(-12, -26), pos + Vector2(-6, -24), Color(0.35, 0.25, 0.20, 0.85), 2.0)
			if ratio <= 0.50:
				canvas.draw_line(pos + Vector2(4, -38), pos + Vector2(12, -36), Color(0.92, 0.82, 0.65), 3.0)
				canvas.draw_line(pos + Vector2(10, -22), pos + Vector2(16, -16), Color(0.25, 0.18, 0.15), 1.5)
			if ratio <= 0.25:
				canvas.draw_circle(pos + Vector2(-8, -42), 4.0, Color(0.2, 0.2, 0.2, 0.5))
				canvas.draw_arc(pos + Vector2(2, -48), 6.0, 0, PI, 6, Color(1, 0.85, 0.25, 0.9), 2.0)
		"bristle":
			if ratio <= 0.75:
				canvas.draw_line(pos + Vector2(-16, -45), pos + Vector2(-8, -48), Color(0.25, 0.18, 0.12), 2.0)
			if ratio <= 0.50:
				canvas.draw_line(pos + Vector2(-6, -55), pos + Vector2(4, -50), Color(0.85, 0.40, 0.20), 2.5)
			if ratio <= 0.25:
				canvas.draw_circle(pos + Vector2(0, -40), 6.0, Color(0.3, 0.15, 0.1, 0.6))
		"monarch":
			if ratio <= 0.75:
				canvas.draw_line(pos + Vector2(-8, -62), pos + Vector2(0, -68), Color(1, 0.85, 0.25), 2.0)
			if ratio <= 0.50:
				canvas.draw_line(pos + Vector2(-12, -40), pos + Vector2(-4, -34), Color(0.65, 0.15, 0.25), 2.5)
			if ratio <= 0.25:
				canvas.draw_arc(pos + Vector2(0, -66), 8.0, PI * 0.2, PI * 1.2, 8, Color(0.9, 0.9, 0.92), 2.0)
		"dusk":
			if ratio <= 0.75:
				canvas.draw_line(pos + Vector2(-10, -35), pos + Vector2(-4, -32), Color(0.15, 0.15, 0.20), 2.0)
			if ratio <= 0.50:
				canvas.draw_line(pos + Vector2(2, -48), pos + Vector2(8, -44), Color(0.9, 0.9, 1.0), 1.5)
			if ratio <= 0.25:
				canvas.draw_circle(pos + Vector2(4, -46), 4.0, Color(0.05, 0.05, 0.08, 0.7))
		"matriarch":
			if ratio <= 0.75:
				canvas.draw_line(pos + Vector2(-28, -6), pos + Vector2(-18, -4), Color(0.35, 0.20, 0.10), 2.5)
			if ratio <= 0.50:
				canvas.draw_line(pos + Vector2(16, -8), pos + Vector2(26, -6), Color(0.35, 0.20, 0.10), 3.0)
			if ratio <= 0.25:
				canvas.draw_circle(pos + Vector2(-20, -18), 5.0, Color(0.25, 0.22, 0.20, 0.6))
				canvas.draw_circle(pos + Vector2(18, -18), 5.0, Color(0.25, 0.22, 0.20, 0.6))

	# Health bar
	var bar := Rect2(pos + Vector2(-32, -height * 0.72), Vector2(64, 7))
	canvas.draw_rect(bar, Color("2d2b2b"))
	canvas.draw_rect(Rect2(bar.position, Vector2(bar.size.x * ratio, bar.size.y)), Color("4fd676").lerp(Color("db5348"), 1.0 - ratio))
	_draw_status(canvas, pos, unit.status, unit.unit_type)

func _draw_projectiles(canvas: CanvasItem, sim) -> void:
	var colors := [Color("f0af3a"), Color("d5564e"), Color("f18735"), Color("a673e5"), Color("77bc59"), Color("38264b"), Color.WHITE]
	for projectile in sim.projectiles:
		if not projectile.is_active:
			continue
		var color: Color = colors[clampi(projectile.damage_type, 0, colors.size() - 1)]

		if projectile.is_explosion:
			# Biscuit lobbed mortar projectile: visible ballistic parabolic arc!
			var total_time := float(projectile.get("total_travel_time", 0.4))
			var left_time := float(projectile.get("travel_time_left", 0.0))
			var prog := clampf(1.0 - left_time / maxf(0.01, total_time), 0.0, 1.0)
			var start_p: Vector2 = projectile.get("start_position", projectile.target_position)
			var ground_p: Vector2 = start_p.lerp(projectile.target_position, prog)
			var arc_y := -sin(prog * PI) * 55.0
			var flight_pos := ground_p + Vector2(0, arc_y)

			# Flying tumbling fishbone
			canvas.draw_set_transform(flight_pos, prog * TAU * 2.0, Vector2.ONE)
			canvas.draw_line(Vector2(-7, 0), Vector2(7, 0), Color(0.96, 0.94, 0.90), 3.0)
			canvas.draw_line(Vector2(-3, -4), Vector2(1, 4), Color(0.96, 0.94, 0.90), 2.0)
			canvas.draw_line(Vector2(2, -4), Vector2(6, 4), Color(0.96, 0.94, 0.90), 2.0)
			canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

			# Target landing reticle
			canvas.draw_arc(projectile.target_position, maxf(8, projectile.radius * (0.3 + 0.2 * prog)), 0, TAU, 18, Color(color, 0.5), 1.5)
		else:
			# Linear projectile: yarn ball for Pip with trailing thread!
			var direction: Vector2 = (projectile.target_position - projectile.position).normalized()
			if projectile.damage_type == 0:
				# Yarn thread trailing
				canvas.draw_line(projectile.position - direction * 16, projectile.position, Color("ffe4b5"), 2.0)
				canvas.draw_circle(projectile.position, 4.0, Color("e67d22"))
				canvas.draw_circle(projectile.position, 2.0, Color("ffd763"))
			else:
				canvas.draw_line(projectile.position - direction * 11, projectile.position, color, 3.0)
				canvas.draw_circle(projectile.position, 3.3, color)

func _draw_sprite(canvas: CanvasItem, texture: Texture2D, pos: Vector2, height: float, flip: bool, frame: int, alpha: float = 1.0) -> void:
	if texture == null:
		return
	var is_sheet := texture.get_width() > texture.get_height() and texture.get_height() >= 64
	var cell_size := texture.get_height() if is_sheet else 128
	var frame_count := maxi(1, int(round(float(texture.get_width()) / float(cell_size)))) if is_sheet else 1
	var aspect := 1.0 if is_sheet else float(texture.get_width()) / float(texture.get_height())
	var size := Vector2(height * aspect, height)
	canvas.draw_set_transform(pos, 0.0, Vector2(-1 if flip else 1, 1))
	var dest := Rect2(Vector2(-size.x * 0.5, -size.y * 0.78), size)
	if is_sheet and frame_count > 1:
		canvas.draw_texture_rect_region(texture, dest, Rect2((frame % frame_count) * cell_size, 0, cell_size, cell_size), Color(1, 1, 1, alpha))
	else:
		canvas.draw_texture_rect(texture, dest, false, Color(1, 1, 1, alpha))
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_shadow(canvas: CanvasItem, pos: Vector2, radius: float) -> void:
	canvas.draw_set_transform(pos, 0.0, Vector2(1.0, 0.38))
	canvas.draw_circle(Vector2.ZERO, radius, Color(0.05, 0.07, 0.04, 0.28))
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_status(canvas: CanvasItem, pos: Vector2, status, unit_type: String = "") -> void:
	# Frost coats ignore freeze and chill: NEVER draw false ice on frost!
	if unit_type == "frost":
		return

	# Freeze: solid crystalline ice crust (faceted diamond ring)
	if status.freeze_time > 0:
		canvas.draw_arc(pos, 16, 0, TAU, 8, Color("a9eaff"), 2.5)
		canvas.draw_arc(pos, 13, PI * 0.125, PI * 2.125, 8, Color(1, 1, 1, 0.8), 1.5)

	# Slow / Chill: soft trailing frost mist at feet
	if not status.slows.is_empty():
		for i in range(3):
			var mist_p := pos + Vector2(-8 + i * 8, 4)
			canvas.draw_circle(mist_p, 2.5, Color(0.40, 0.80, 0.95, 0.65))

	if status.burn_time > 0:
		canvas.draw_circle(pos + Vector2(0, -15), 4, Color("f07b37"))
	if status.mark_time > 0:
		canvas.draw_arc(pos, 11, 0, TAU, 12, Color("f5d557"), 1.5)
	if status.hex_time > 0:
		canvas.draw_string(ThemeDB.fallback_font, pos + Vector2(-5, -15), "✧", HORIZONTAL_ALIGNMENT_CENTER, 10, 13, Color("bd78f0"))
	if status.stun_time > 0:
		canvas.draw_string(ThemeDB.fallback_font, pos + Vector2(-8, -22), "✦ ✦", HORIZONTAL_ALIGNMENT_CENTER, 16, 10, Color("fff2a2"))

func _draw_ornament(canvas: CanvasItem, tower) -> void:
	var ta: int = int(tower.tiers.get("path_a", 0))
	var tb: int = int(tower.tiers.get("path_b", 0))
	var tc: int = int(tower.tiers.get("path_c", 0))
	var tiers_list := [ta, tb, tc]
	tiers_list.sort()
	var primary_tier: int = int(tiers_list[2])
	var secondary_tier: int = int(tiers_list[1])

	if primary_tier <= 0:
		return

	# Primary path ornament
	var pri_color := Color("ffd76a") if primary_tier >= 5 else Color("c9eff7") if primary_tier >= 3 else Color("e9aa65")
	# Base arc
	canvas.draw_arc(tower.position + Vector2(0, 5), tower.footprint_radius + 5, PI * 1.08, PI * 1.92, 14, pri_color, 2.5)
	# Primary pips on front
	for i in range(primary_tier):
		canvas.draw_circle(tower.position + Vector2(-8 + i * 4, 20), 2.0, pri_color)

	if primary_tier >= 5:
		# Tier 5: Radiant golden crown
		canvas.draw_arc(tower.position, tower.footprint_radius + 9, 0, TAU, 32, Color(pri_color, 0.55), 2.0)
		canvas.draw_arc(tower.position, tower.footprint_radius + 13, 0, TAU, 32, Color(pri_color, 0.25), 1.0)
		canvas.draw_string(ThemeDB.fallback_font, tower.position + Vector2(-6, -tower.footprint_radius - 12), "👑", HORIZONTAL_ALIGNMENT_CENTER, 12, 12, Color("ffd76a"))
	elif primary_tier >= 3:
		# Tier 3: Silver crescent crest
		canvas.draw_arc(tower.position, tower.footprint_radius + 7, PI * 0.7, PI * 1.3, 16, Color(pri_color, 0.65), 2.0)

	# Secondary path ornament: visually distinct crosspath badge on opposite flank
	if secondary_tier >= 1:
		var sec_color := Color("e9aa65") if secondary_tier == 1 else Color("d58c42")
		# Secondary flanking arc on top flank
		canvas.draw_arc(tower.position + Vector2(0, -5), tower.footprint_radius + 4, PI * 0.08, PI * 0.92, 12, sec_color, 1.8)
		# Secondary pips
		for j in range(secondary_tier):
			canvas.draw_circle(tower.position + Vector2(-4 + j * 6, -tower.footprint_radius - 6), 1.8, sec_color)

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
