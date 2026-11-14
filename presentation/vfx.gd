class_name CombatVfx
extends RefCounted

const MAX_EFFECTS := 80
var effects: Array[Dictionary] = []
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
	if kind in ["pop", "blocked", "hit", "kibble", "status", "ability", "upgrade", "child"]:
		var effect := event.duplicate(true)
		effect["age"] = 0.0
		effect["life"] = 0.55 if kind != "child" else 0.27
		effects.append(effect)

func advance(delta: float) -> void:
	leak_flash = maxf(0.0, leak_flash - delta)
	var live: Array[Dictionary] = []
	for effect in effects:
		effect.age += delta
		if effect.age < effect.life:
			live.append(effect)
	effects = live

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
	if leak_flash > 0.0:
		canvas.draw_rect(Rect2(0, 0, 1280, 720), Color(0.85, 0.1, 0.08, leak_flash * 0.42), false, 10.0)

func _draw_pop(canvas: CanvasItem, pos: Vector2, coat: String, t: float) -> void:
	var colors := {"rust": Color("d76c3a"), "frost": Color("a9e7f4"), "ink": Color("7451a8"), "iron": Color("b0b4bb"), "soot": Color("5a5354")}
	var color: Color = colors.get(coat, Color("e7b35e"))
	for i in range(7):
		var p := pos + Vector2.from_angle(float(i) * TAU / 7.0) * (8.0 + 25.0 * t)
		canvas.draw_circle(p, 4.5 * (1.0 - t), Color(color, 1.0 - t))

func _draw_blocked(canvas: CanvasItem, pos: Vector2, blocked_by: String, t: float) -> void:
	var color := Color("b2b7bf") if blocked_by == "iron" else Color("77606d") if blocked_by == "soot" else Color("a968d8")
	canvas.draw_arc(pos, 14 + t * 8, 0, TAU, 12, Color(color, 1.0 - t), 2.5)
	var text := "HELD" if blocked_by == "matriarch" else "CLANG" if blocked_by == "iron" else "PUFF" if blocked_by == "soot" else "SWALLOW"
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
