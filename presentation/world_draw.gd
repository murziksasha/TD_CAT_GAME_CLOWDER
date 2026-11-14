class_name WorldDraw
extends RefCounted

const SimMatch = preload("res://sim/match.gd")

func draw_world(canvas: CanvasItem, grass: Texture2D, cobble: Texture2D, props: Dictionary, sim: SimMatch = null) -> void:
	var map_key := sim.map_id if sim != null else "sunny_gutter"
	if grass:
		canvas.draw_texture_rect(grass, Rect2(0, 0, 1280, 720), false, _ground_tint(map_key))
	else:
		canvas.draw_rect(Rect2(0, 0, 1280, 720), _ground_tint(map_key))
	_draw_map_architecture(canvas, map_key)
	if sim != null:
		_draw_water_zones(canvas, sim)
		_draw_perches(canvas, sim)
	
	if sim != null and not sim.paths.is_empty():
		for p_info in sim.paths:
			var pts: Array = p_info.points
			var packed := PackedVector2Array()
			for pt in pts:
				packed.append(pt)
			_draw_polyline_path(canvas, packed, cobble)
	else:
		_draw_polyline_path(canvas, path_points(), cobble)
		
	# Draw sight blockers
	if sim != null and not sim.sight_blockers.is_empty():
		for blocker in sim.sight_blockers:
			var stall_tex: Texture2D = props.get("stall")
			if stall_tex != null:
				canvas.draw_texture_rect(stall_tex, blocker, false)
			else:
				canvas.draw_rect(blocker, Color(0.4, 0.25, 0.15))
	if sim != null:
		_draw_removable_obstacles(canvas, props, sim)
	var decoration := _decoration_for(map_key)
	_draw_prop(canvas, props.get("lantern"), decoration.get("lantern", Vector2(180, 250)), 82)
	_draw_prop(canvas, props.get("puddle"), decoration.get("puddle", Vector2(1080, 260)), 100)
	_draw_prop(canvas, props.get("stall"), decoration.get("stall", Vector2(1080, 410)), 130)

func path_points() -> PackedVector2Array:
	return PackedVector2Array([Vector2(40, 100), Vector2(640, 100), Vector2(640, 400), Vector2(340, 400)])

func _draw_houses(canvas: CanvasItem) -> void:
	# Painterly, code-drawn fallback set dressing; every rectangle stays off the cobble ribbon.
	for house in [
		{"rect": Rect2(90, 175, 150, 78), "roof": Color("b84c32")},
		{"rect": Rect2(430, 190, 140, 70), "roof": Color("8b5238")},
		{"rect": Rect2(720, 70, 170, 95), "roof": Color("cc7330")},
		{"rect": Rect2(900, 330, 150, 80), "roof": Color("704860")},
		{"rect": Rect2(70, 500, 90, 55), "roof": Color("9e4d29")}
	]:
		var r: Rect2 = house.rect
		canvas.draw_rect(Rect2(r.position + Vector2(6, 5), r.size), Color(0.06, 0.08, 0.05, 0.16))
		canvas.draw_rect(r, Color("f1dfbd"))
		canvas.draw_colored_polygon(PackedVector2Array([r.position + Vector2(-8, 0), r.position + Vector2(r.size.x + 8, 0), r.position + Vector2(r.size.x * 0.5, -30)]), house.roof)
		canvas.draw_rect(Rect2(r.position + Vector2(r.size.x * 0.5 - 9, r.size.y - 22), Vector2(18, 22)), Color("70411f"))
		canvas.draw_rect(Rect2(r.position + Vector2(16, 22), Vector2(18, 16)), Color("f7ca68"))

func _ground_tint(map_key: String) -> Color:
	var night := map_key in ["canal_night", "night_onion", "the_warren"]
	var market := map_key in ["market_lane", "stall_row", "grand_bazaar", "fishmarket_maze"]
	if night:
		return Color("355d5b")
	if market:
		return Color("88a36a")
	return Color("a9bd82")

func _decoration_for(map_key: String) -> Dictionary:
	var decorations := {
		"sunny_gutter": {"lantern": Vector2(265, 245), "puddle": Vector2(860, 230), "stall": Vector2(1080, 510)},
		"lantern_stoop": {"lantern": Vector2(340, 285), "puddle": Vector2(930, 530), "stall": Vector2(1020, 250)},
		"puddle_court": {"lantern": Vector2(820, 130), "puddle": Vector2(440, 355), "stall": Vector2(980, 520)},
		"canal_night": {"lantern": Vector2(850, 120), "puddle": Vector2(930, 260), "stall": Vector2(1070, 540)},
		"grand_bazaar": {"lantern": Vector2(780, 170), "puddle": Vector2(970, 560), "stall": Vector2(600, 250)},
		"the_warren": {"lantern": Vector2(790, 330), "puddle": Vector2(1040, 180), "stall": Vector2(1000, 480)}
	}
	return decorations.get(map_key, {"lantern": Vector2(160, 560), "puddle": Vector2(1060, 170), "stall": Vector2(1080, 410)})

func _draw_map_architecture(canvas: CanvasItem, map_key: String) -> void:
	# Fixed, map-keyed architecture keeps the playing field readable while every ward
	# has its own silhouette, roof palette, and edge composition.
	var palettes := {
		"canal_night": [Color("385b68"), Color("613e54")],
		"night_onion": [Color("49385e"), Color("2d5360")],
		"grand_bazaar": [Color("b65735"), Color("d28a3d")],
		"fishmarket_maze": [Color("4d7280"), Color("b46539")]
	}
	var colors: Array = palettes.get(map_key, [Color("b85b38"), Color("86513b")])
	var seed: int = absi(map_key.hash())
	var variant: int = seed % 5
	var houses: Array[Rect2]
	if map_key == "sunny_gutter":
		# The canonical route must remain completely clear of architecture.
		houses = [Rect2(90, 175, 150, 78), Rect2(720, 30, 170, 60), Rect2(900, 500, 150, 80), Rect2(70, 500, 90, 55)]
	else:
		# Hash-derived values are still fixed per map id: every map has a distinct,
		# stable edge composition without leaking art coordinates into the sim.
		houses = [
			Rect2(18 + (seed % 60), 18 + variant * 9, 140 + (seed % 45), 76 + variant * 5),
			Rect2(960 + ((seed / 7) % 85), 24 + ((seed / 11) % 30), 170 + ((seed / 13) % 40), 88 + variant * 4),
			Rect2(1010 + ((seed / 17) % 60), 330 + ((seed / 19) % 105), 150 + ((seed / 23) % 45), 88 + variant * 5),
			Rect2(22 + ((seed / 29) % 80), 545 + ((seed / 31) % 55), 130 + ((seed / 37) % 45), 72 + variant * 4)
		]
	for i in range(houses.size()):
		var r := houses[i]
		canvas.draw_rect(Rect2(r.position + Vector2(7, 8), r.size), Color(0.04, 0.08, 0.08, 0.22))
		canvas.draw_rect(r, Color("e8d4ad"))
		canvas.draw_colored_polygon(PackedVector2Array([r.position + Vector2(-10, 0), r.position + Vector2(r.size.x + 10, 0), r.position + Vector2(r.size.x * 0.5, -28)]), colors[i % colors.size()])
		canvas.draw_rect(Rect2(r.position + Vector2(20, 30), Vector2(22, 18)), Color("78a6a4"))
		canvas.draw_rect(Rect2(r.position + Vector2(r.size.x * 0.5 - 10, r.size.y - 24), Vector2(20, 24)), Color("674022"))

func _draw_water_zones(canvas: CanvasItem, sim: SimMatch) -> void:
	for zone in sim.placement_zones.get("water", []):
		if not (zone is Dictionary):
			continue
		var center := Vector2(float(zone.get("x", 0.0)), float(zone.get("y", 0.0)))
		var radius := float(zone.get("radius", 0.0))
		if radius > 0.0:
			canvas.draw_circle(center + Vector2(3, 5), radius + 4, Color("376a6d"))
			canvas.draw_circle(center, radius, Color(0.24, 0.58, 0.66, 0.92))
			var shimmer := sin(Time.get_ticks_msec() * 0.0016 + center.x * 0.02) * 0.22
			canvas.draw_arc(center, radius * (0.62 + shimmer * 0.08), 0.3, 2.4, 16, Color(0.78, 0.92, 0.85, 0.38), 2.0)

func _draw_perches(canvas: CanvasItem, sim: SimMatch) -> void:
	for perch in sim.placement_zones.get("perches", []):
		if not (perch is Dictionary):
			continue
		var center := Vector2(float(perch.get("x", 0.0)), float(perch.get("y", 0.0)))
		var radius := float(perch.get("radius", 24.0))
		canvas.draw_circle(center + Vector2(2, 4), radius + 2, Color(0.08, 0.13, 0.12, 0.25))
		canvas.draw_circle(center, radius, Color("b88b4d"))
		canvas.draw_arc(center, radius - 4, 0.0, TAU, 18, Color("f1d48a"), 1.5)

func _draw_removable_obstacles(canvas: CanvasItem, props: Dictionary, sim: SimMatch) -> void:
	for obstacle in sim.get_removable_obstacles():
		var base: Dictionary = obstacle.get("base", {})
		var rect := Rect2(float(base.get("x", 0.0)), float(base.get("y", 0.0)), float(base.get("width", 0.0)), float(base.get("height", 0.0)))
		canvas.draw_rect(Rect2(rect.position + Vector2(4, 6), rect.size), Color(0.05, 0.07, 0.04, 0.30))
		var crates: Texture2D = props.get("crates")
		if crates != null:
			canvas.draw_texture_rect(crates, rect.grow(8), false, Color.WHITE)
		else:
			canvas.draw_rect(rect, Color("79502d"))
		canvas.draw_dashed_line(rect.position, Vector2(rect.end.x, rect.position.y), Color("ffe08a"), 1.5, 5.0)

func _draw_polyline_path(canvas: CanvasItem, points: PackedVector2Array, cobble: Texture2D) -> void:
	if points.size() < 2:
		return
	canvas.draw_polyline(points, Color("49301c"), 54.0, true)
	if cobble == null:
		canvas.draw_polyline(points, Color("9e805c"), 40.0, true)
		return
	for i in range(points.size() - 1):
		var a: Vector2 = points[i]
		var b: Vector2 = points[i + 1]
		canvas.draw_set_transform(a, (b - a).angle(), Vector2.ONE)
		canvas.draw_texture_rect(cobble, Rect2(0, -20, a.distance_to(b), 40), false, Color(1, 0.96, 0.9))
		canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	canvas.draw_circle(points[0], 16, Color("408c48"))
	canvas.draw_circle(points[-1], 18, Color("bf3828"))

func _draw_path(canvas: CanvasItem, cobble: Texture2D) -> void:
	_draw_polyline_path(canvas, path_points(), cobble)

func _draw_prop(canvas: CanvasItem, tex: Texture2D, pos: Vector2, height: float) -> void:
	if tex == null:
		return
	canvas.draw_set_transform(pos + Vector2(0, height * 0.28), 0.0, Vector2(1, 0.38))
	canvas.draw_circle(Vector2.ZERO, height * 0.28, Color(0.05, 0.07, 0.04, 0.28))
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var scale := height / float(tex.get_height())
	var width := float(tex.get_width()) * scale
	canvas.draw_texture_rect(tex, Rect2(pos - Vector2(width * 0.5, height * 0.55), Vector2(width, height)), false, Color.WHITE)
