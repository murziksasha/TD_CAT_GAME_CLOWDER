class_name CombatVfx
extends RefCounted

const MAX_EFFECTS := 128
var effects: Array[Dictionary] = []
var debris: Array[Dictionary] = []
var reduced: bool = false
var shake_mode: int = 1 # 0 off, 1 low, 2 full
var leak_flash: float = 0.0

func note(event: Dictionary) -> void:
	var kind := str(event.get("type", ""))
	if kind == "leak":
		leak_flash = 0.35
	if effects.size() >= MAX_EFFECTS:
		if reduced or kind in ["kibble", "hit"]:
			return
		effects.pop_front()

	var pos := Vector2(float(event.get("x", 0.0)), float(event.get("y", 0.0)))

	if kind == "pop":
		var coat := str(event.get("coat", "")).to_lower()
		var unit_type := str(event.get("unit_type", "")).to_lower()
		var is_rat := bool(event.get("is_rat", false)) or unit_type in ["burrow", "bristle", "monarch", "dusk", "matriarch"]
		_spawn_pop_debris(pos, coat, unit_type, is_rat)

	if kind in ["pop", "blocked", "hit", "kibble", "status", "ability", "upgrade", "child", "explosion", "frost_pulse", "slash"]:
		var effect := event.duplicate(true)
		effect["age"] = 0.0
		var life := 0.55
		match kind:
			"child": life = 0.27
			"explosion": life = 0.38
			"frost_pulse": life = 0.35
			"slash": life = 0.24
			"pop": life = 0.32
		effect["life"] = life
		effects.append(effect)

func _spawn_pop_debris(pos: Vector2, coat: String, unit_type: String, is_rat: bool) -> void:
	# Rats equipment flying off
	if is_rat or unit_type in ["burrow", "bristle", "monarch", "dusk", "matriarch"]:
		match unit_type:
			"matriarch":
				# Catastrophic throne platform collapse
				for i in range(4):
					debris.append({
						"kind": "throne_timber", "pos": pos + Vector2(randf_range(-25, 25), -15),
						"vel": Vector2(randf_range(-60, 60), randf_range(-180, -90)),
						"gravity": 440.0, "rot": 0.0, "vrot": randf_range(-12.0, 12.0),
						"life": 0.55, "max_life": 0.55
					})
			"monarch":
				# Golden crown falling + red velvet mantle ribbons
				debris.append({
					"kind": "crown", "pos": pos + Vector2(0, -35),
					"vel": Vector2(randf_range(-30, 30), randf_range(-130, -90)),
					"gravity": 420.0, "rot": 0.0, "vrot": randf_range(-8.0, 8.0),
					"life": 0.48, "max_life": 0.48
				})
			"bristle":
				# Barbed spine plates rattling off
				for i in range(4):
					debris.append({
						"kind": "barbed_spine", "pos": pos + Vector2(randf_range(-15, 15), -20),
						"vel": Vector2(randf_range(-70, 70), randf_range(-120, -60)),
						"gravity": 400.0, "rot": randf_range(0, TAU), "vrot": randf_range(-14.0, 14.0),
						"life": 0.42, "max_life": 0.42
					})
			"dusk":
				# Dark sunglasses + smoke plume
				debris.append({
					"kind": "dark_glasses", "pos": pos + Vector2(0, -25),
					"vel": Vector2(randf_range(-40, 40), randf_range(-110, -70)),
					"gravity": 360.0, "rot": 0.0, "vrot": randf_range(-10.0, 10.0),
					"life": 0.40, "max_life": 0.40
				})
			_:
				# Burrow hardhat
				debris.append({
					"kind": "hardhat", "pos": pos + Vector2(0, -20),
					"vel": Vector2(randf_range(-35, 35), randf_range(-140, -100)),
					"gravity": 420.0, "rot": 0.0, "vrot": randf_range(-10.0, 10.0),
					"life": 0.48, "max_life": 0.48
				})
		return

	# Mice equipment flying off
	match coat:
		"iron":
			debris.append({
				"kind": "bucket", "pos": pos + Vector2(0, -10),
				"vel": Vector2(randf_range(-45, 45), randf_range(-160, -110)),
				"gravity": 460.0, "rot": 0.0, "vrot": randf_range(-14.0, 14.0),
				"life": 0.46, "max_life": 0.46
			})
		"porcelain":
			for i in range(5):
				var ang := float(i) * TAU / 5.0 + randf_range(-0.3, 0.3)
				var spd := randf_range(60.0, 110.0)
				debris.append({
					"kind": "ceramic_shard", "pos": pos,
					"vel": Vector2(cos(ang) * spd, sin(ang) * spd - 40.0),
					"gravity": 360.0, "rot": randf_range(0, TAU), "vrot": randf_range(-16.0, 16.0),
					"life": 0.32, "max_life": 0.32
				})
		"grain":
			debris.append({
				"kind": "satchel", "pos": pos,
				"vel": Vector2(randf_range(-40, 40), randf_range(-110, -70)),
				"gravity": 380.0, "rot": 0.0, "vrot": randf_range(-8.0, 8.0),
				"life": 0.36, "max_life": 0.36
			})
		"slate":
			debris.append({
				"kind": "newsboy_cap", "pos": pos + Vector2(0, -12),
				"vel": Vector2(randf_range(-35, 35), randf_range(-120, -80)),
				"gravity": 380.0, "rot": 0.0, "vrot": randf_range(-10.0, 10.0),
				"life": 0.38, "max_life": 0.38
			})
		"moss":
			debris.append({
				"kind": "leaf_glide", "pos": pos + Vector2(0, -15),
				"vel": Vector2(randf_range(-25, 25), randf_range(-70, -40)),
				"gravity": 180.0, "rot": 0.0, "vrot": randf_range(-6.0, 6.0),
				"life": 0.45, "max_life": 0.45
			})
		"sugar":
			debris.append({
				"kind": "lollipop", "pos": pos + Vector2(0, -10),
				"vel": Vector2(randf_range(-40, 40), randf_range(-130, -90)),
				"gravity": 400.0, "rot": 0.0, "vrot": randf_range(-12.0, 12.0),
				"life": 0.40, "max_life": 0.40
			})
		"soot":
			for i in range(4):
				debris.append({
					"kind": "soot_cloud", "pos": pos,
					"vel": Vector2(randf_range(-40, 40), randf_range(-60, 10)),
					"gravity": 160.0, "rot": 0.0, "vrot": 0.0,
					"life": 0.30, "max_life": 0.30
				})
		"frost":
			debris.append({
				"kind": "scarf_ribbon", "pos": pos,
				"vel": Vector2(randf_range(-30, 30), randf_range(-80, -40)),
				"gravity": 220.0, "rot": 0.0, "vrot": randf_range(-8.0, 8.0),
				"life": 0.42, "max_life": 0.42
			})
		"ink":
			debris.append({
				"kind": "wizard_hat", "pos": pos + Vector2(0, -15),
				"vel": Vector2(randf_range(-35, 35), randf_range(-120, -80)),
				"gravity": 380.0, "rot": 0.0, "vrot": randf_range(-10.0, 10.0),
				"life": 0.40, "max_life": 0.40
			})
		"marble":
			for i in range(3):
				debris.append({
					"kind": "stone_rubble", "pos": pos,
					"vel": Vector2(randf_range(-50, 50), randf_range(-90, -30)),
					"gravity": 440.0, "rot": randf_range(0, TAU), "vrot": randf_range(-8.0, 8.0),
					"life": 0.36, "max_life": 0.36
				})
		"prism":
			for i in range(4):
				debris.append({
					"kind": "rainbow_prism", "pos": pos,
					"vel": Vector2(randf_range(-60, 60), randf_range(-100, -40)),
					"gravity": 320.0, "rot": randf_range(0, TAU), "vrot": randf_range(-15.0, 15.0),
					"life": 0.32, "max_life": 0.32
				})

func advance(delta: float) -> void:
	leak_flash = maxf(0.0, leak_flash - delta)
	var live_fx: Array[Dictionary] = []
	for effect in effects:
		effect.age += delta
		if effect.age < effect.life:
			live_fx.append(effect)
	effects = live_fx

	var live_deb: Array[Dictionary] = []
	for deb in debris:
		deb.vel.y += deb.gravity * delta
		deb.pos += deb.vel * delta
		deb.rot += deb.vrot * delta
		deb.life -= delta
		if deb.life > 0.0:
			live_deb.append(deb)
	debris = live_deb

func draw(canvas: CanvasItem) -> void:
	for effect in effects:
		var pos := Vector2(float(effect.get("x", 0.0)), float(effect.get("y", 0.0)))
		var t := float(effect.age) / maxf(0.01, float(effect.life))
		match str(effect.type):
			"pop": _draw_pop(canvas, pos, str(effect.get("coat", "rust")), t)
			"blocked": _draw_blocked(canvas, pos, str(effect.get("blocked_by", "")), t)
			"hit": _draw_hit(canvas, pos, int(effect.get("damage_type", 0)), t)
			"kibble": _draw_floater(canvas, pos, "+%d" % int(effect.get("amount", 0)), Color("f5ce58"), t)
			"status": _draw_floater(canvas, pos, str(effect.get("status", "")).capitalize(), Color("b9edff"), t)
			"ability", "upgrade": _draw_starburst(canvas, pos, t)
			"child": canvas.draw_arc(pos, 10.0 + t * 7.0, 0, TAU, 12, Color(1, 1, 1, 1.0 - t), 1.5)
			"explosion": _draw_explosion(canvas, pos, float(effect.get("radius", 45.0)), t)
			"frost_pulse": _draw_frost_pulse(canvas, pos, float(effect.get("radius", 90.0)), t)
			"slash": _draw_slash(canvas, pos, float(effect.get("radius", 40.0)), t)

	for deb in debris:
		var alpha: float = clampf(float(deb.life) / float(deb.max_life), 0.0, 1.0)
		canvas.draw_set_transform(deb.pos, deb.rot, Vector2.ONE)
		match str(deb.kind):
			"bucket":
				canvas.draw_rect(Rect2(-8, -12, 16, 14), Color(0.65, 0.68, 0.72, alpha), true)
				canvas.draw_rect(Rect2(-8, -12, 16, 14), Color(0.35, 0.38, 0.42, alpha), false, 1.5)
			"crown":
				canvas.draw_polygon([Vector2(-8, 6), Vector2(-10, -6), Vector2(-3, 0), Vector2(0, -8), Vector2(3, 0), Vector2(10, -6), Vector2(8, 6)], [Color(1.0, 0.85, 0.25, alpha)])
			"barbed_spine":
				canvas.draw_line(Vector2(-3, -8), Vector2(3, 8), Color(0.75, 0.50, 0.30, alpha), 3.0)
			"dark_glasses":
				canvas.draw_rect(Rect2(-8, -4, 16, 8), Color(0.15, 0.15, 0.18, alpha), true)
			"throne_timber":
				canvas.draw_rect(Rect2(-12, -4, 24, 8), Color(0.48, 0.30, 0.15, alpha), true)
			"hardhat":
				canvas.draw_circle(Vector2(0, 0), 10, Color(0.96, 0.68, 0.15, alpha))
			"ceramic_shard":
				var pts := PackedVector2Array([Vector2(-4, -6), Vector2(6, -3), Vector2(2, 6), Vector2(-5, 3)])
				canvas.draw_colored_polygon(pts, Color(0.96, 0.95, 0.92, alpha))
			"satchel":
				canvas.draw_rect(Rect2(-6, -5, 12, 10), Color(0.62, 0.38, 0.18, alpha), true)
			"newsboy_cap":
				canvas.draw_circle(Vector2.ZERO, 7.0, Color(0.32, 0.36, 0.42, alpha))
				canvas.draw_line(Vector2(-7, 3), Vector2(7, 3), Color(0.22, 0.26, 0.32, alpha), 2.0)
			"leaf_glide":
				canvas.draw_polygon([Vector2(-4, 6), Vector2(6, -6), Vector2(0, -8)], [Color(0.35, 0.68, 0.25, alpha)])
			"lollipop":
				canvas.draw_circle(Vector2.ZERO, 7, Color(0.96, 0.52, 0.68, alpha))
				canvas.draw_line(Vector2(0, 7), Vector2(0, 16), Color(0.9, 0.9, 0.9, alpha), 2.0)
			"soot_cloud":
				canvas.draw_circle(Vector2.ZERO, 4.5 * alpha, Color(0.20, 0.18, 0.17, alpha * 0.7))
			"scarf_ribbon":
				canvas.draw_line(Vector2(-6, -6), Vector2(6, 6), Color(0.35, 0.75, 0.88, alpha), 3.0)
			"wizard_hat":
				canvas.draw_polygon([Vector2(-8, 6), Vector2(0, -12), Vector2(8, 6)], [Color(0.28, 0.15, 0.42, alpha)])
			"stone_rubble":
				canvas.draw_rect(Rect2(-4, -4, 8, 8), Color(0.50, 0.58, 0.62, alpha), true)
			"rainbow_prism":
				canvas.draw_polygon([Vector2(-4, 5), Vector2(0, -6), Vector2(4, 5)], [Color(0.85, 0.60, 0.92, alpha)])
		canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	if leak_flash > 0.0:
		canvas.draw_rect(Rect2(0, 0, 1280, 720), Color(0.85, 0.1, 0.08, leak_flash * 0.42), false, 10.0)

func _draw_pop(canvas: CanvasItem, pos: Vector2, coat: String, t: float) -> void:
	var colors := {
		"rust": Color("d76c3a"), "frost": Color("a9e7f4"), "ink": Color("7451a8"),
		"iron": Color("b0b4bb"), "soot": Color("5a5354"), "grain": Color("d9ad36"),
		"slate": Color("71808f"), "moss": Color("4a7d38"), "sugar": Color("f39aac"),
		"marble": Color("599eaf"), "prism": Color("d866d7"), "porcelain": Color("f5f3e9")
	}
	var color: Color = colors.get(coat, Color("e7b35e"))
	for i in range(7):
		var p := pos + Vector2.from_angle(float(i) * TAU / 7.0) * (8.0 + 25.0 * t)
		canvas.draw_circle(p, 4.5 * (1.0 - t), Color(color, 1.0 - t))

func _draw_blocked(canvas: CanvasItem, pos: Vector2, blocked_by: String, t: float) -> void:
	var b := blocked_by.to_lower()
	var color := Color("b2b7bf") if b == "iron" else Color("77606d") if b == "soot" else Color("64c5d9") if b == "frost" else Color("a968d8")
	canvas.draw_arc(pos, 14 + t * 8, 0, TAU, 16, Color(color, 1.0 - t), 2.5)
	if b == "iron":
		for i in range(4):
			var sp := pos + Vector2.from_angle(float(i) * TAU / 4.0 + 0.4) * (10.0 + t * 14.0)
			canvas.draw_circle(sp, 2.0 * (1.0 - t), Color(1, 0.95, 0.6, 1.0 - t))
	var text := "HELD" if b == "matriarch" else "CLANG" if b == "iron" else "PUFF" if b == "soot" else "FROST" if b == "frost" else "SWALLOW"
	_draw_floater(canvas, pos, text, color, t)

func _draw_hit(canvas: CanvasItem, pos: Vector2, damage_type: int, t: float) -> void:
	var colors := [Color("f0af3a"), Color("d5564e"), Color("f18735"), Color("a673e5"), Color("77bc59"), Color("38264b"), Color.WHITE]
	var color: Color = colors[clampi(damage_type, 0, colors.size() - 1)]
	canvas.draw_line(pos - Vector2(8, 8), pos + Vector2(8, 8), Color(color, 1.0 - t), 2.5)
	canvas.draw_line(pos + Vector2(8, -8), pos - Vector2(8, 8), Color(color, 1.0 - t), 2.5)

func _draw_floater(canvas: CanvasItem, pos: Vector2, label: String, color: Color, t: float) -> void:
	canvas.draw_string(ThemeDB.fallback_font, pos + Vector2(-20, -18 - 24 * t), label, HORIZONTAL_ALIGNMENT_CENTER, 40, 11, Color(color, 1.0 - t))

func _draw_starburst(canvas: CanvasItem, pos: Vector2, t: float) -> void:
	for i in range(5):
		canvas.draw_line(pos, pos + Vector2.from_angle(float(i) * TAU / 5.0) * (14 + t * 18), Color(1, 0.82, 0.28, 1.0 - t), 2.0)

func _draw_explosion(canvas: CanvasItem, pos: Vector2, radius: float, t: float) -> void:
	var r := radius * (0.3 + 0.7 * sin(t * PI * 0.5))
	var alpha := 1.0 - t
	canvas.draw_arc(pos, r, 0, TAU, 28, Color(1.0, 0.75, 0.25, alpha * 0.9), 3.0 * alpha)
	canvas.draw_arc(pos, r * 0.75, 0, TAU, 24, Color(0.95, 0.40, 0.15, alpha * 0.6), 2.0 * alpha)
	canvas.draw_circle(pos, maxf(4.0, r * 0.45 * (1.0 - t)), Color(1.0, 0.88, 0.45, alpha))
	for i in range(5):
		var ang := float(i) * TAU / 5.0 + 0.3
		var puff_pos := pos + Vector2(cos(ang), sin(ang)) * (r * 0.65 * t)
		canvas.draw_circle(puff_pos, maxf(3.0, 12.0 * (1.0 - t)), Color(0.35, 0.32, 0.30, alpha * 0.45))

func _draw_frost_pulse(canvas: CanvasItem, pos: Vector2, radius: float, t: float) -> void:
	var current_r := radius * (0.2 + 0.8 * sqrt(t))
	var alpha := 1.0 - t
	canvas.draw_circle(pos, current_r, Color(0.60, 0.85, 1.0, alpha * 0.12))
	canvas.draw_arc(pos, current_r, 0, TAU, 48, Color(0.72, 0.92, 1.0, alpha * 0.95), 2.5)
	for i in range(6):
		var ang := float(i) * TAU / 6.0
		var p := pos + Vector2(cos(ang), sin(ang)) * current_r
		canvas.draw_circle(p, 3.0 * alpha, Color(0.90, 0.98, 1.0, alpha))

func _draw_slash(canvas: CanvasItem, pos: Vector2, radius: float, t: float) -> void:
	var alpha := 1.0 - t
	var r := maxf(18.0, radius * 0.8)
	canvas.draw_arc(pos, r, -PI * 0.3, PI * 0.9, 24, Color(1.0, 1.0, 1.0, alpha * 0.9), 3.5)
	canvas.draw_arc(pos, r + 5.0, -PI * 0.25, PI * 0.85, 24, Color(0.65, 0.82, 1.0, alpha * 0.7), 2.0)
