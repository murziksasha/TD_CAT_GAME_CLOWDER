class_name WorldDraw
extends RefCounted

const SimMatch = preload("res://sim/match.gd")

func draw_world(canvas: CanvasItem, grass: Texture2D, cobble: Texture2D, props: Dictionary, sim: SimMatch = null) -> void:
	if grass:
		canvas.draw_texture_rect(grass, Rect2(0, 0, 1280, 720), false, Color(0.92, 0.98, 0.88))
	else:
		canvas.draw_rect(Rect2(0, 0, 1280, 720), Color(0.36, 0.52, 0.28))
	_draw_houses(canvas)
	
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
				
	_draw_prop(canvas, props.get("puddle"), Vector2(860, 230), 150)
	_draw_prop(canvas, props.get("lantern"), Vector2(180, 250), 90)
	_draw_prop(canvas, props.get("lantern"), Vector2(760, 150), 80)
	_draw_prop(canvas, props.get("crates"), Vector2(980, 520), 130)
	_draw_prop(canvas, props.get("stall"), Vector2(200, 530), 170)

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
