class_name HudIcon
extends Control

@export_enum("heart", "bowl", "level") var kind: String = "heart"
var level_value: int = 1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if kind == "level":
		custom_minimum_size = Vector2(44, 24)
	else:
		custom_minimum_size = Vector2(22, 20)

func set_level(val: int) -> void:
	level_value = val
	queue_redraw()

func _draw() -> void:
	var c := size * 0.5
	match kind:
		"heart":
			# Code-drawn warm terracotta/coral heart
			var r := minf(size.x, size.y) * 0.25
			var fill := Color(0.95, 0.32, 0.28)
			var hi := Color(1.0, 0.65, 0.58)
			var rim := Color(0.32, 0.10, 0.08)
			var left_c := c + Vector2(-r * 0.85, -r * 0.4)
			var right_c := c + Vector2(r * 0.85, -r * 0.4)
			var tip := c + Vector2(0, r * 1.9)
			var poly := PackedVector2Array([
				left_c + Vector2(-r * 0.95, 0.0),
				left_c + Vector2(0.0, -r * 0.85),
				c + Vector2(0.0, -r * 0.1),
				right_c + Vector2(0.0, -r * 0.85),
				right_c + Vector2(r * 0.95, 0.0),
				tip
			])
			draw_circle(left_c, r, rim)
			draw_circle(right_c, r, rim)
			draw_colored_polygon(poly, fill)
			draw_circle(left_c, r * 0.88, fill)
			draw_circle(right_c, r * 0.88, fill)
			draw_circle(left_c + Vector2(-r * 0.2, -r * 0.25), r * 0.28, hi)
		"bowl":
			# Code-drawn brass-rimmed kibble bowl with golden kibble mound
			var w := minf(size.x, 22.0) * 0.44
			var h := minf(size.y, 20.0) * 0.34
			# Kibble nuggets mound
			var kibble_col := Color(0.96, 0.78, 0.30)
			var kibble_dark := Color(0.76, 0.52, 0.16)
			draw_circle(c + Vector2(-w * 0.35, -h * 0.35), 2.8, kibble_dark)
			draw_circle(c + Vector2(w * 0.32, -h * 0.35), 2.8, kibble_dark)
			draw_circle(c + Vector2(0, -h * 0.6), 3.1, kibble_col)
			draw_circle(c + Vector2(-w * 0.18, -h * 0.25), 2.4, kibble_col)
			draw_circle(c + Vector2(w * 0.18, -h * 0.25), 2.4, kibble_col)
			# Bowl body
			var bowl := PackedVector2Array([
				c + Vector2(-w, -h * 0.1),
				c + Vector2(w, -h * 0.1),
				c + Vector2(w * 0.72, h * 1.15),
				c + Vector2(-w * 0.72, h * 1.15)
			])
			draw_colored_polygon(bowl, Color(0.76, 0.34, 0.18))
			draw_line(c + Vector2(-w, -h * 0.1), c + Vector2(w, -h * 0.1), Color(0.95, 0.78, 0.36), 2.2)
		"level":
			# Code-drawn brass level medallion
			var rect := Rect2(Vector2.ZERO, size)
			draw_rect(rect, Color(0.26, 0.16, 0.08, 0.95), true)
			draw_rect(rect, Color(0.93, 0.72, 0.32), false, 1.5)
			draw_string(ThemeDB.fallback_font, Vector2(0, size.y * 0.72), "LV %d" % level_value, HORIZONTAL_ALIGNMENT_CENTER, int(size.x), 12, Color(1.0, 0.90, 0.40))
