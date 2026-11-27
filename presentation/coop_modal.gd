# Clowder: Alley Siege - Co-op Multiplayer Setup Modal
class_name CoopModal
extends PanelContainer

const NetworkMgr = preload("res://network/network_manager.gd")

signal closed
signal start_local_coop
signal start_network_coop(is_host: bool)

var net_mgr: NetworkMgr = null
var status_lbl: Label = null
var ip_edit: LineEdit = null
var port_edit: LineEdit = null
var host_btn: Button = null
var join_btn: Button = null
var local_btn: Button = null

func setup(p_net_mgr: NetworkMgr) -> void:
	net_mgr = p_net_mgr
	_build_ui()
	_bind_network_signals()

func _build_ui() -> void:
	custom_minimum_size = Vector2(560, 420)
	offset_left = 360.0
	offset_top = 150.0
	offset_right = 920.0
	offset_bottom = 570.0

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 14)
	add_child(root_vbox)

	# Header
	var header_hbox := HBoxContainer.new()
	root_vbox.add_child(header_hbox)

	var title_lbl := Label.new()
	title_lbl.text = "Clowder Co-op"
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(title_lbl)

	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(func():
		visible = false
		closed.emit()
	)
	header_hbox.add_child(close_btn)

	root_vbox.add_child(HSeparator.new())

	# Option 1: Local Co-op
	var local_section := VBoxContainer.new()
	local_section.add_theme_constant_override("separation", 6)
	root_vbox.add_child(local_section)

	var local_title := Label.new()
	local_title.text = "1. Local Shared-Screen Co-op (2 Players on 1 PC)"
	local_title.add_theme_font_size_override("font_size", 15)
	local_title.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	local_section.add_child(local_title)

	var local_desc := Label.new()
	local_desc.text = "Player 1 (Teal Collar) & Player 2 (Orange Collar) deploy cats together.\nEach player chooses a Hero Cat. Shared kibble purse & dual defense!"
	local_desc.add_theme_font_size_override("font_size", 12)
	local_desc.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	local_section.add_child(local_desc)

	local_btn = Button.new()
	local_btn.text = "⚔ Launch Local Co-op Match"
	local_btn.custom_minimum_size = Vector2(0, 36)
	local_btn.add_theme_color_override("font_color", Color(0.4, 0.95, 0.5))
	local_btn.pressed.connect(func():
		visible = false
		start_local_coop.emit()
	)
	local_section.add_child(local_btn)

	root_vbox.add_child(HSeparator.new())

	# Option 2: LAN / Online Co-op
	var net_section := VBoxContainer.new()
	net_section.add_theme_constant_override("separation", 8)
	root_vbox.add_child(net_section)

	var net_title := Label.new()
	net_title.text = "2. LAN / Direct IP Co-op (Deterministic ENet)"
	net_title.add_theme_font_size_override("font_size", 15)
	net_title.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	net_section.add_child(net_title)

	var net_inputs := HBoxContainer.new()
	net_inputs.add_theme_constant_override("separation", 8)
	net_section.add_child(net_inputs)

	var ip_lbl := Label.new()
	ip_lbl.text = "Host IP:"
	net_inputs.add_child(ip_lbl)

	ip_edit = LineEdit.new()
	ip_edit.text = "127.0.0.1"
	ip_edit.custom_minimum_size = Vector2(160, 32)
	net_inputs.add_child(ip_edit)

	var port_lbl := Label.new()
	port_lbl.text = "Port:"
	net_inputs.add_child(port_lbl)

	port_edit = LineEdit.new()
	port_edit.text = "7777"
	port_edit.custom_minimum_size = Vector2(70, 32)
	net_inputs.add_child(port_edit)

	var net_actions := HBoxContainer.new()
	net_actions.add_theme_constant_override("separation", 10)
	net_section.add_child(net_actions)

	host_btn = Button.new()
	host_btn.text = "🏠 Host Game (Server)"
	host_btn.custom_minimum_size = Vector2(170, 36)
	host_btn.pressed.connect(_on_host_pressed)
	net_actions.add_child(host_btn)

	join_btn = Button.new()
	join_btn.text = "🔗 Join Game (Client)"
	join_btn.custom_minimum_size = Vector2(170, 36)
	join_btn.pressed.connect(_on_join_pressed)
	net_actions.add_child(join_btn)

	status_lbl = Label.new()
	status_lbl.text = "Ready to connect or host."
	status_lbl.add_theme_font_size_override("font_size", 13)
	status_lbl.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	net_section.add_child(status_lbl)

func _bind_network_signals() -> void:
	if net_mgr == null:
		return
	net_mgr.peer_joined.connect(func(id: int):
		status_lbl.text = "✓ Teammate joined! (Peer ID %d). Ready to siege!" % id
		status_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	)
	net_mgr.connection_succeeded.connect(func():
		status_lbl.text = "✓ Connected to host! Synchronizing battle..."
		status_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
		visible = false
		start_network_coop.emit(false)
	)
	net_mgr.connection_failed.connect(func():
		status_lbl.text = "✗ Connection failed! Check IP and Port."
		status_lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	)

func _on_host_pressed() -> void:
	if net_mgr == null:
		return
	var port = int(port_edit.text)
	var err = net_mgr.host_match(port)
	if err == OK:
		status_lbl.text = "★ Server hosting on port %d. Waiting for teammate..." % port
		status_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
		visible = false
		start_network_coop.emit(true)
	else:
		status_lbl.text = "Failed to host on port %d." % port
		status_lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))

func _on_join_pressed() -> void:
	if net_mgr == null:
		return
	var ip = ip_edit.text.strip_edges()
	var port = int(port_edit.text)
	status_lbl.text = "Connecting to %s:%d..." % [ip, port]
	net_mgr.join_match(ip, port)
