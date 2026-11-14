# Clowder: Alley Siege - Shop & Collector's Vault Modal
class_name ShopModal
extends PanelContainer

const SimSaveManager = preload("res://sim/save_manager.gd")

signal closed

var save_mgr: SimSaveManager
var current_tab: String = "regular"

var wallet_lbl: Label
var tabs_hbox: HBoxContainer
var items_vbox: VBoxContainer

var shop_data: Dictionary = {}
var tricks_data: Dictionary = {}
var prestige_data: Dictionary = {}

func setup(p_save_mgr: SimSaveManager) -> void:
	save_mgr = p_save_mgr
	_load_shop_content()
	_build_ui()
	_select_tab("regular")

func _load_shop_content() -> void:
	shop_data = _read_json("res://content/shop.json")
	tricks_data = _read_json("res://content/tricks.json")
	prestige_data = _read_json("res://content/prestige_shop.json")

func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f = FileAccess.open(path, FileAccess.READ)
	if not f:
		return {}
	var text = f.get_as_text()
	f.close()
	var res = JSON.parse_string(text)
	return res if (res is Dictionary) else {}

func _build_ui() -> void:
	custom_minimum_size = Vector2(980, 620)
	offset_left = 150.0
	offset_top = 50.0
	offset_right = 1130.0
	offset_bottom = 670.0

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 8)
	add_child(root_vbox)

	# Header Bar
	var header_hbox := HBoxContainer.new()
	root_vbox.add_child(header_hbox)

	var title_lbl := Label.new()
	title_lbl.text = "🛍 The Alley Market & Collector's Vault"
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(title_lbl)

	wallet_lbl = Label.new()
	wallet_lbl.text = "🐟 0 Fishcoin | 🦴 0 Golden Bones  "
	wallet_lbl.add_theme_font_size_override("font_size", 16)
	wallet_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7))
	header_hbox.add_child(wallet_lbl)

	var close_btn := Button.new()
	close_btn.text = " ✕ Close "
	close_btn.pressed.connect(func():
		visible = false
		closed.emit()
	)
	header_hbox.add_child(close_btn)

	root_vbox.add_child(HSeparator.new())

	# Tabs Bar
	tabs_hbox = HBoxContainer.new()
	tabs_hbox.add_theme_constant_override("separation", 10)
	root_vbox.add_child(tabs_hbox)

	_add_tab_button("regular", "🐟 Alley Market (Fishcoin)")
	_add_tab_button("vault", "🦴 Collector's Vault (Super Shop)")

	root_vbox.add_child(HSeparator.new())

	# Scrollable Item List
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_vbox.add_child(scroll)

	items_vbox = VBoxContainer.new()
	items_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	items_vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(items_vbox)

func _add_tab_button(tab_id: String, tab_title: String) -> void:
	var btn := Button.new()
	btn.text = tab_title
	btn.custom_minimum_size = Vector2(220, 36)
	btn.pressed.connect(func(): _select_tab(tab_id))
	tabs_hbox.add_child(btn)

func _update_wallet() -> void:
	if save_mgr != null and wallet_lbl != null:
		var eco: Dictionary = save_mgr.data.get("economy", {})
		var fish = int(eco.get("fishcoin", 0))
		var bones = int(eco.get("golden_bones", 0))
		wallet_lbl.text = "🐟 %d Fishcoin | 🦴 %d Golden Bones  " % [fish, bones]

func _select_tab(tab_id: String) -> void:
	current_tab = tab_id
	_update_wallet()

	for child in items_vbox.get_children():
		items_vbox.remove_child(child)
		child.queue_free()

	if tab_id == "regular":
		_render_regular_shop()
	else:
		_render_prestige_shop()

func _render_regular_shop() -> void:
	# 1. Combat Tricks
	var trk_hdr := Label.new()
	trk_hdr.text = "⚡ Combat Tricks (Equippable Actives):"
	trk_hdr.add_theme_font_size_override("font_size", 16)
	trk_hdr.add_theme_color_override("font_color", Color(0.5, 0.9, 1.0))
	items_vbox.add_child(trk_hdr)

	var trks: Dictionary = tricks_data.get("tricks", {})
	for tid in trks.keys():
		var t = trks[tid]
		var item_id = "trick_" + tid
		var price = int(t.get("price", 250))
		var desc = "In-match: %d Kibble | Cooldown: %d rounds" % [t.get("kibble_cost", 50), t.get("cooldown_rounds", 15)]
		_create_item_row(item_id, t.get("name", tid), price, desc, false, 0.40)

	items_vbox.add_child(HSeparator.new())

	# 2. Cosmetics & Looks
	var cos_hdr := Label.new()
	cos_hdr.text = "🎨 Cat Looks, Trails & UI Frames:"
	cos_hdr.add_theme_font_size_override("font_size", 16)
	cos_hdr.add_theme_color_override("font_color", Color(1.0, 0.8, 0.5))
	items_vbox.add_child(cos_hdr)

	var cosmetics: Array = shop_data.get("cosmetics", [])
	for c in cosmetics:
		var item_id = c.get("id", "")
		var price = int(c.get("price", 100))
		var desc = "Category: %s" % str(c.get("category", "")).replace("_", " ").capitalize()
		_create_item_row(item_id, c.get("name", item_id), price, desc, false, 0.50)

func _render_prestige_shop() -> void:
	var info := Label.new()
	info.text = "🏆 Exclusive high-mastery trophies for dedicated alley cats. Earned ONLY through skill and activity!"
	info.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	items_vbox.add_child(info)

	var items: Array = prestige_data.get("items", [])
	for item in items:
		var item_id = item.get("id", "")
		var price = int(item.get("price", 25))
		var desc = item.get("desc", "")
		_create_item_row(item_id, item.get("name", item_id), price, desc, true, 0.0)

func _create_item_row(item_id: String, item_name: String, price: int, desc: String, is_prestige: bool, resell_ratio: float) -> void:
	var is_owned = save_mgr.is_item_owned(item_id) if save_mgr else false

	var panel := PanelContainer.new()
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	panel.add_child(hbox)

	var info_vbox := VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)

	var title := Label.new()
	title.text = item_name
	title.add_theme_font_size_override("font_size", 16)
	if is_prestige:
		title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
	elif is_owned:
		title.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
	info_vbox.add_child(title)

	var desc_lbl := Label.new()
	desc_lbl.text = desc
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_vbox.add_child(desc_lbl)

	# Action Buttons (Buy / Sell)
	var btn_hbox := HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 6)
	hbox.add_child(btn_hbox)

	if is_owned:
		var owned_lbl := Label.new()
		owned_lbl.text = "✓ OWNED "
		owned_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
		btn_hbox.add_child(owned_lbl)

		# Resell button for regular items
		if not is_prestige and resell_ratio > 0.0:
			var refund = int(floor(float(price) * resell_ratio))
			var sell_btn := Button.new()
			sell_btn.text = "Resell (+%d 🐟)" % refund
			sell_btn.pressed.connect(func():
				_sell_item(item_id, refund)
			)
			btn_hbox.add_child(sell_btn)
	else:
		var buy_btn := Button.new()
		var currency_sym = "🦴" if is_prestige else "🐟"
		buy_btn.text = "Buy (%d %s)" % [price, currency_sym]
		buy_btn.custom_minimum_size = Vector2(130, 38)
		if is_prestige:
			buy_btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))

		var can_afford = false
		if save_mgr != null:
			var cur = save_mgr.data.get("economy", {}).get("golden_bones" if is_prestige else "fishcoin", 0)
			can_afford = cur >= price
		buy_btn.disabled = not can_afford

		if can_afford:
			buy_btn.pressed.connect(func():
				if save_mgr.buy_shop_item(item_id, price, is_prestige):
					_select_tab(current_tab)
			)
		btn_hbox.add_child(buy_btn)

	items_vbox.add_child(panel)

func _sell_item(item_id: String, refund: int) -> void:
	if save_mgr == null:
		return
	var eco: Dictionary = save_mgr.data.get("economy", {})
	var owned: Array = eco.get("owned_shop_ids", [])
	if owned.has(item_id):
		owned.erase(item_id)
		eco["owned_shop_ids"] = owned
		eco["fishcoin"] = int(eco.get("fishcoin", 0)) + refund
		save_mgr.data["economy"] = eco
		save_mgr.save_profile()
		_select_tab(current_tab)
