class_name WoodTheme
extends RefCounted

static func panel_style() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.17, 0.10, 0.06, 0.94)
	box.border_color = Color(0.93, 0.72, 0.32)
	box.set_border_width_all(2)
	box.set_corner_radius_all(14)
	box.shadow_color = Color(0, 0, 0, 0.4)
	box.shadow_size = 10
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	return box

static func card_style(selected: bool = false) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.24, 0.14, 0.08, 0.96) if selected else Color(0.14, 0.08, 0.05, 0.92)
	box.border_color = Color(1.0, 0.88, 0.42) if selected else Color(0.68, 0.50, 0.24)
	box.set_border_width_all(2)
	box.set_corner_radius_all(10)
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	return box

static func button_style(border: Color, fill: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(8)
	box.content_margin_left = 8
	box.content_margin_right = 8
	box.content_margin_top = 5
	box.content_margin_bottom = 5
	return box

static func apply_to_tree(root: Node, font_scale: float = 1.0) -> void:
	var p_style := panel_style()
	var normal := button_style(Color(0.93, 0.72, 0.32), Color(0.40, 0.22, 0.10))
	var hover := button_style(Color(1.0, 0.86, 0.45), Color(0.55, 0.32, 0.12))
	var pressed := button_style(Color(0.75, 0.52, 0.18), Color(0.24, 0.12, 0.06))
	_walk_apply(root, p_style, normal, hover, pressed, font_scale)

static func _walk_apply(node: Node, p_style: StyleBoxFlat, normal: StyleBoxFlat, hover: StyleBoxFlat, pressed: StyleBoxFlat, font_scale: float) -> void:
	if node is PanelContainer:
		if not node.has_meta("_keep_custom_panel"):
			node.add_theme_stylebox_override("panel", p_style)
	elif node is Button:
		node.add_theme_stylebox_override("normal", normal)
		node.add_theme_stylebox_override("hover", hover)
		node.add_theme_stylebox_override("pressed", pressed)
		node.add_theme_stylebox_override("disabled", pressed)
		if not node.has_theme_color_override("font_color"):
			node.add_theme_color_override("font_color", Color(1.0, 0.96, 0.88))
		node.add_theme_color_override("font_hover_color", Color(1.0, 0.92, 0.55))
		node.add_theme_color_override("font_disabled_color", Color(0.68, 0.60, 0.50))
	elif node is Label:
		if node.name != "LivesLabel" and node.name != "KibbleLabel" and not node.has_theme_color_override("font_color"):
			node.add_theme_color_override("font_color", Color(1.0, 0.95, 0.86))
	if node is Label or node is Button:
		if not node.has_meta("_base_font_size"):
			var cur := int(node.get_theme_font_size("font_size"))
			node.set_meta("_base_font_size", cur if cur > 0 else 14)
		var base_sz := int(node.get_meta("_base_font_size", 14))
		var effective_scale := font_scale
		# Keep compact bars readable inside fixed footprints without overflowing the Sunny ribbon.
		if node.get_parent() != null and (node.get_parent().name == "HBox" or node.get_parent().name == "SpeedContainer"):
			effective_scale = minf(font_scale, 1.25)
		node.add_theme_font_size_override("font_size", int(round(float(base_sz) * effective_scale)))
	for child in node.get_children():
		_walk_apply(child, p_style, normal, hover, pressed, font_scale)
