class_name WorldDraw
extends RefCounted

const SimMatch = preload("res://sim/match.gd")

func draw_world(canvas: CanvasItem, grass: Texture2D, cobble: Texture2D, props: Dictionary, sim: SimMatch = null, leak_flash: float = 0.0) -> void:
	var map_key := sim.map_id if sim != null else "sunny_gutter"
	var tint := _ground_tint(map_key)
	if grass != null:
		# Tile grass cleanly across 1280x720 instead of stretching one rectangle.
		var tile_sz := 256.0
		var gx := 0.0
		while gx < 1280.0:
			var gy := 0.0
			while gy < 720.0:
				var w := minf(tile_sz, 1280.0 - gx)
				var h := minf(tile_sz, 720.0 - gy)
				var region := Rect2(0, 0, w * (float(grass.get_width()) / tile_sz), h * (float(grass.get_height()) / tile_sz))
				canvas.draw_texture_rect_region(grass, Rect2(gx, gy, w, h), region, tint)
				gy += tile_sz
			gx += tile_sz
	else:
		canvas.draw_rect(Rect2(0, 0, 1280, 720), tint)

	_draw_map_architecture(canvas, map_key, sim)
	if sim != null:
		_draw_water_zones(canvas, sim)
		_draw_perches(canvas, sim)

	var path_list: Array[PackedVector2Array] = []
	if sim != null and not sim.paths.is_empty():
		for p_info in sim.paths:
			var pts: Array = p_info.points
			var packed := PackedVector2Array()
			for pt in pts:
				packed.append(pt)
			path_list.append(packed)
	else:
		path_list.append(path_points())

	for packed_pts in path_list:
		_draw_polyline_path(canvas, packed_pts, cobble)

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

	_draw_map_props(canvas, map_key, props)

	# Wordless entrance & exit marks on every path
	for packed_pts in path_list:
		if packed_pts.size() >= 2:
			_draw_entrance_exit(canvas, packed_pts[0], packed_pts[packed_pts.size() - 1], props, leak_flash)

func path_points() -> PackedVector2Array:
	return PackedVector2Array([Vector2(40, 100), Vector2(640, 100), Vector2(640, 400), Vector2(340, 400)])

func _ground_tint(map_key: String) -> Color:
	var night := map_key in ["canal_night", "night_onion", "the_warren"]
	var market := map_key in ["market_lane", "stall_row", "grand_bazaar", "fishmarket_maze", "spice_arcade", "herring_square"]
	if night:
		return Color("355d5b")
	if market:
		return Color("88a36a")
	return Color("a9bd82")

func _map_prop_layout(map_key: String) -> Array[Dictionary]:
	if map_key == "sunny_gutter":
		# Off the canonical (40,100)->(640,100)->(640,400)->(340,400) ribbon, perches, water, and obstacles.
		return [
			{"id": "stoop", "pos": Vector2(150, 225), "height": 115.0},
			{"id": "awning", "pos": Vector2(455, 225), "height": 112.0},
			{"id": "lantern", "pos": Vector2(280, 240), "height": 78.0},
			{"id": "hanging_wash", "pos": Vector2(125, 500), "height": 120.0},
			{"id": "stall", "pos": Vector2(260, 520), "height": 116.0},
			{"id": "crate_stack", "pos": Vector2(775, 485), "height": 108.0},
			{"id": "lantern", "pos": Vector2(740, 350), "height": 76.0},
			{"id": "puddle", "pos": Vector2(855, 345), "height": 86.0}
		]
	var layouts := {
		"basket_bridge": [{"id": "puddle", "pos": Vector2(569, 103), "height": 84.0}, {"id": "hanging_wash", "pos": Vector2(734, 116), "height": 108.0}, {"id": "stoop", "pos": Vector2(127, 209), "height": 104.0}, {"id": "lantern", "pos": Vector2(347, 201), "height": 76.0}, {"id": "crate_stack", "pos": Vector2(842, 202), "height": 98.0}],
		"canal_night": [{"id": "lantern", "pos": Vector2(784, 118), "height": 78.0}, {"id": "crate_stack", "pos": Vector2(89, 241), "height": 98.0}, {"id": "lantern", "pos": Vector2(197, 327), "height": 78.0}, {"id": "puddle", "pos": Vector2(802, 343), "height": 86.0}, {"id": "stoop", "pos": Vector2(85, 421), "height": 104.0}],
		"canopy_cross": [{"id": "stoop", "pos": Vector2(516, 111), "height": 104.0}, {"id": "awning", "pos": Vector2(681, 105), "height": 106.0}, {"id": "crate_stack", "pos": Vector2(846, 118), "height": 98.0}, {"id": "lantern", "pos": Vector2(294, 209), "height": 76.0}, {"id": "hanging_wash", "pos": Vector2(73, 243), "height": 108.0}],
		"chimney_step": [{"id": "stoop", "pos": Vector2(731, 116), "height": 104.0}, {"id": "awning", "pos": Vector2(124, 209), "height": 106.0}, {"id": "crate_stack", "pos": Vector2(289, 203), "height": 98.0}, {"id": "lantern", "pos": Vector2(454, 197), "height": 76.0}, {"id": "hanging_wash", "pos": Vector2(839, 202), "height": 108.0}],
		"copper_scale": [{"id": "stoop", "pos": Vector2(85, 113), "height": 104.0}, {"id": "awning", "pos": Vector2(250, 107), "height": 106.0}, {"id": "crate_stack", "pos": Vector2(415, 101), "height": 98.0}, {"id": "lantern", "pos": Vector2(635, 112), "height": 76.0}, {"id": "hanging_wash", "pos": Vector2(800, 106), "height": 108.0}],
		"crabapple_bend": [{"id": "stoop", "pos": Vector2(731, 102), "height": 104.0}, {"id": "awning", "pos": Vector2(839, 207), "height": 106.0}, {"id": "crate_stack", "pos": Vector2(91, 242), "height": 98.0}, {"id": "lantern", "pos": Vector2(256, 236), "height": 76.0}, {"id": "hanging_wash", "pos": Vector2(421, 249), "height": 108.0}],
		"fig_and_twine": [{"id": "stoop", "pos": Vector2(78, 119), "height": 104.0}, {"id": "awning", "pos": Vector2(243, 113), "height": 106.0}, {"id": "crate_stack", "pos": Vector2(408, 107), "height": 98.0}, {"id": "lantern", "pos": Vector2(573, 101), "height": 76.0}, {"id": "hanging_wash", "pos": Vector2(738, 114), "height": 108.0}],
		"fishbone_straight": [{"id": "stoop", "pos": Vector2(354, 104), "height": 104.0}, {"id": "awning", "pos": Vector2(75, 294), "height": 106.0}, {"id": "crate_stack", "pos": Vector2(240, 288), "height": 98.0}, {"id": "lantern", "pos": Vector2(405, 282), "height": 76.0}, {"id": "hanging_wash", "pos": Vector2(570, 295), "height": 108.0}],
		"fishmarket_maze": [{"id": "awning", "pos": Vector2(577, 117), "height": 106.0}, {"id": "stall", "pos": Vector2(742, 111), "height": 112.0}, {"id": "crate_stack", "pos": Vector2(80, 206), "height": 98.0}, {"id": "lantern", "pos": Vector2(850, 197), "height": 76.0}, {"id": "hanging_wash", "pos": Vector2(244, 245), "height": 108.0}],
		"grand_bazaar": [{"id": "awning", "pos": Vector2(528, 111), "height": 106.0}, {"id": "stall", "pos": Vector2(693, 105), "height": 112.0}, {"id": "crate_stack", "pos": Vector2(858, 118), "height": 98.0}, {"id": "lantern", "pos": Vector2(85, 243), "height": 76.0}, {"id": "hanging_wash", "pos": Vector2(250, 237), "height": 108.0}],
		"herring_square": [{"id": "awning", "pos": Vector2(736, 115), "height": 106.0}, {"id": "stall", "pos": Vector2(844, 201), "height": 112.0}, {"id": "crate_stack", "pos": Vector2(73, 236), "height": 98.0}, {"id": "lantern", "pos": Vector2(238, 249), "height": 76.0}, {"id": "hanging_wash", "pos": Vector2(513, 239), "height": 108.0}],
		"lantern_stoop": [{"id": "lantern", "pos": Vector2(738, 106), "height": 78.0}, {"id": "stoop", "pos": Vector2(75, 246), "height": 108.0}, {"id": "lantern", "pos": Vector2(240, 240), "height": 78.0}, {"id": "awning", "pos": Vector2(405, 253), "height": 106.0}, {"id": "crate_stack", "pos": Vector2(513, 339), "height": 98.0}],
		"market_lane": [{"id": "awning", "pos": Vector2(349, 104), "height": 106.0}, {"id": "stall", "pos": Vector2(844, 105), "height": 112.0}, {"id": "crate_stack", "pos": Vector2(896, 238), "height": 98.0}, {"id": "lantern", "pos": Vector2(70, 294), "height": 76.0}, {"id": "hanging_wash", "pos": Vector2(235, 288), "height": 108.0}],
		"morning_arch": [{"id": "lantern", "pos": Vector2(624, 101), "height": 76.0}, {"id": "stoop", "pos": Vector2(789, 114), "height": 106.0}, {"id": "lantern", "pos": Vector2(126, 254), "height": 76.0}, {"id": "awning", "pos": Vector2(676, 253), "height": 106.0}, {"id": "crate_stack", "pos": Vector2(400, 289), "height": 98.0}],
		"night_onion": [{"id": "lantern", "pos": Vector2(404, 104), "height": 78.0}, {"id": "crate_stack", "pos": Vector2(569, 117), "height": 98.0}, {"id": "lantern", "pos": Vector2(734, 111), "height": 78.0}, {"id": "puddle", "pos": Vector2(842, 197), "height": 86.0}, {"id": "stoop", "pos": Vector2(621, 250), "height": 104.0}],
		"puddle_court": [{"id": "puddle", "pos": Vector2(692, 111), "height": 88.0}, {"id": "hanging_wash", "pos": Vector2(857, 105), "height": 108.0}, {"id": "stoop", "pos": Vector2(84, 249), "height": 104.0}, {"id": "lantern", "pos": Vector2(799, 242), "height": 76.0}, {"id": "crate_stack", "pos": Vector2(248, 288), "height": 98.0}],
		"rooftop_crossing": [{"id": "stoop", "pos": Vector2(523, 107), "height": 104.0}, {"id": "awning", "pos": Vector2(688, 101), "height": 106.0}, {"id": "crate_stack", "pos": Vector2(853, 114), "height": 98.0}, {"id": "lantern", "pos": Vector2(191, 209), "height": 76.0}, {"id": "hanging_wash", "pos": Vector2(685, 236), "height": 108.0}],
		"sack_corner": [{"id": "stoop", "pos": Vector2(787, 114), "height": 104.0}, {"id": "awning", "pos": Vector2(895, 200), "height": 106.0}, {"id": "crate_stack", "pos": Vector2(69, 237), "height": 98.0}, {"id": "lantern", "pos": Vector2(234, 250), "height": 76.0}, {"id": "hanging_wash", "pos": Vector2(399, 244), "height": 108.0}],
		"spice_arcade": [{"id": "awning", "pos": Vector2(87, 109), "height": 106.0}, {"id": "stall", "pos": Vector2(252, 103), "height": 112.0}, {"id": "crate_stack", "pos": Vector2(417, 116), "height": 98.0}, {"id": "lantern", "pos": Vector2(582, 110), "height": 76.0}, {"id": "hanging_wash", "pos": Vector2(802, 102), "height": 108.0}],
		"stall_row": [{"id": "awning", "pos": Vector2(79, 102), "height": 106.0}, {"id": "stall", "pos": Vector2(244, 115), "height": 112.0}, {"id": "crate_stack", "pos": Vector2(574, 103), "height": 98.0}, {"id": "lantern", "pos": Vector2(849, 112), "height": 76.0}, {"id": "hanging_wash", "pos": Vector2(130, 299), "height": 108.0}],
		"the_warren": [{"id": "lantern", "pos": Vector2(684, 115), "height": 78.0}, {"id": "crate_stack", "pos": Vector2(849, 109), "height": 98.0}, {"id": "lantern", "pos": Vector2(77, 208), "height": 78.0}, {"id": "puddle", "pos": Vector2(242, 202), "height": 86.0}, {"id": "stoop", "pos": Vector2(407, 196), "height": 104.0}],
		"twin_gutters": [{"id": "stoop", "pos": Vector2(571, 117), "height": 104.0}, {"id": "awning", "pos": Vector2(736, 111), "height": 106.0}, {"id": "crate_stack", "pos": Vector2(74, 206), "height": 98.0}, {"id": "lantern", "pos": Vector2(349, 196), "height": 76.0}, {"id": "hanging_wash", "pos": Vector2(844, 197), "height": 108.0}],
		"two_purse_lane": [{"id": "stoop", "pos": Vector2(80, 111), "height": 104.0}, {"id": "awning", "pos": Vector2(245, 105), "height": 106.0}, {"id": "crate_stack", "pos": Vector2(520, 114), "height": 98.0}, {"id": "lantern", "pos": Vector2(685, 108), "height": 76.0}, {"id": "hanging_wash", "pos": Vector2(76, 291), "height": 108.0}],
		"weigh_house": [{"id": "stoop", "pos": Vector2(676, 102), "height": 104.0}, {"id": "awning", "pos": Vector2(841, 115), "height": 106.0}, {"id": "crate_stack", "pos": Vector2(91, 240), "height": 98.0}, {"id": "lantern", "pos": Vector2(256, 253), "height": 76.0}, {"id": "hanging_wash", "pos": Vector2(696, 237), "height": 108.0}],
		"welcome_bridge": [{"id": "puddle", "pos": Vector2(683, 119), "height": 86.0}, {"id": "hanging_wash", "pos": Vector2(848, 113), "height": 108.0}, {"id": "stoop", "pos": Vector2(75, 238), "height": 104.0}, {"id": "lantern", "pos": Vector2(460, 243), "height": 76.0}, {"id": "crate_stack", "pos": Vector2(680, 254), "height": 98.0}]
	}
	if layouts.has(map_key):
		var typed: Array[Dictionary] = []
		for item in layouts[map_key]:
			typed.append(item)
		return typed
	return [
		{"id": "lantern", "pos": Vector2(160, 560), "height": 80.0},
		{"id": "puddle", "pos": Vector2(1060, 170), "height": 90.0},
		{"id": "stall", "pos": Vector2(1080, 410), "height": 120.0}
	]

func _draw_map_props(canvas: CanvasItem, map_key: String, props: Dictionary) -> void:
	var is_night := map_key in ["canal_night", "night_onion", "the_warren"]
	for entry in _map_prop_layout(map_key):
		var pid := str(entry.get("id", ""))
		var pos: Vector2 = entry.get("pos", Vector2.ZERO)
		var tex: Texture2D = props.get(pid)
		if is_night and pid == "lantern":
			canvas.draw_circle(pos + Vector2(0, -10), 46.0, Color(0.98, 0.72, 0.28, 0.14))
		_draw_prop(canvas, tex, pos, float(entry.get("height", 90.0)))

func _rect_clears_paths(rect: Rect2, sim: SimMatch) -> bool:
	if sim == null or sim.paths.is_empty():
		return true
	var margin := float(sim.map_data.get("path_width", 40.0)) * 0.5 + 24.0
	var expanded := rect.grow(margin)
	for p_info in sim.paths:
		var pts: Array = p_info.get("points", [])
		for i in range(pts.size() - 1):
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[i + 1]
			var steps := maxi(2, int(ceil(a.distance_to(b) / 24.0)))
			for s_i in range(steps + 1):
				var t := float(s_i) / float(steps)
				if expanded.has_point(a.lerp(b, t)):
					return false
	return true

func _draw_map_architecture(canvas: CanvasItem, map_key: String, sim: SimMatch = null) -> void:
	# Sunny Gutter retires rectangle houses in favor of the Stage 2 storybook prop kit.
	if map_key == "sunny_gutter":
		return
	var palettes := {
		"canal_night": [Color("385b68"), Color("613e54")],
		"night_onion": [Color("49385e"), Color("2d5360")],
		"grand_bazaar": [Color("b65735"), Color("d28a3d")],
		"fishmarket_maze": [Color("4d7280"), Color("b46539")]
	}
	var colors: Array = palettes.get(map_key, [Color("b85b38"), Color("86513b")])
	var seed_val: int = absi(map_key.hash())
	var variant: int = seed_val % 5
	var houses: Array[Rect2] = [
		Rect2(18 + (seed_val % 60), 18 + variant * 9, 140 + (seed_val % 45), 76 + variant * 5),
		Rect2(960 + ((seed_val / 7) % 85), 24 + ((seed_val / 11) % 30), 170 + ((seed_val / 13) % 40), 88 + variant * 4),
		Rect2(1010 + ((seed_val / 17) % 60), 330 + ((seed_val / 19) % 105), 150 + ((seed_val / 23) % 45), 88 + variant * 5),
		Rect2(22 + ((seed_val / 29) % 80), 545 + ((seed_val / 31) % 55), 130 + ((seed_val / 37) % 45), 72 + variant * 4)
	]
	for i in range(houses.size()):
		var r := houses[i]
		if not _rect_clears_paths(r, sim):
			continue
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
	# Soft feathered grass-to-cobble transition ribbon
	canvas.draw_polyline(points, Color(0.24, 0.22, 0.14, 0.24), 66.0, true)
	canvas.draw_polyline(points, Color(0.36, 0.27, 0.17, 0.72), 54.0, true)
	canvas.draw_polyline(points, Color("9e805c"), 44.0, true)
	if cobble != null:
		var tile_len := 64.0
		var tex_w := float(cobble.get_width())
		var tex_h := float(cobble.get_height())
		for i in range(points.size() - 1):
			var a: Vector2 = points[i]
			var b: Vector2 = points[i + 1]
			var seg_len := a.distance_to(b)
			var ang := (b - a).angle()
			canvas.draw_set_transform(a, ang, Vector2.ONE)
			var d := 0.0
			while d < seg_len:
				var chunk := minf(tile_len, seg_len - d)
				var src_w := tex_w * (chunk / tile_len)
				canvas.draw_texture_rect_region(cobble, Rect2(d, -21, chunk, 42), Rect2(0, 0, src_w, minf(tex_h, 512.0)), Color(1.0, 0.96, 0.88))
				d += tile_len
			canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# Soft corner joint caps so cobble bends blend smoothly
		for i in range(1, points.size() - 1):
			canvas.draw_circle(points[i], 21.0, Color(0.76, 0.65, 0.50, 0.82))
			canvas.draw_arc(points[i], 21.0, 0, TAU, 16, Color(0.42, 0.30, 0.18, 0.55), 2.0)

func _draw_entrance_exit(canvas: CanvasItem, start_pt: Vector2, end_pt: Vector2, props: Dictionary, leak_flash: float) -> void:
	# Entrance: wordless mouse-hole arch
	var hole_tex: Texture2D = props.get("mouse_hole")
	if hole_tex != null:
		_draw_prop(canvas, hole_tex, start_pt, 56.0)
	else:
		canvas.draw_circle(start_pt, 18.0, Color("7f6a52"))
		canvas.draw_circle(start_pt + Vector2(0, 2), 11.0, Color("20181d"))

	# Exit: wordless tipped fish basket, pulsing on leak
	if leak_flash > 0.0:
		var pulse := clampf(leak_flash / 0.35, 0.0, 1.0)
		var ring_r := 26.0 + (1.0 - pulse) * 26.0
		canvas.draw_circle(end_pt, ring_r, Color(0.92, 0.28, 0.18, pulse * 0.30))
		canvas.draw_arc(end_pt, ring_r, 0, TAU, 28, Color(1.0, 0.42, 0.26, pulse * 0.95), 3.5)

	var basket_tex: Texture2D = props.get("fish_basket")
	if basket_tex != null:
		_draw_prop(canvas, basket_tex, end_pt, 54.0)
	else:
		canvas.draw_circle(end_pt, 18.0, Color("b87b3c"))
		canvas.draw_arc(end_pt, 18.0, 0, TAU, 20, Color("5a3618"), 2.5)

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
