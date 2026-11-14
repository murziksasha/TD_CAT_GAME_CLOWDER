# Clowder: Alley Siege - Network & Co-op Multiplayer Manager
class_name NetworkManager
extends Node

const DEFAULT_PORT: int = 7777

signal connection_succeeded
signal connection_failed
signal server_disconnected
signal peer_joined(id: int)
signal peer_left(id: int)
signal match_started(seed_val: int, map_id: String, mode: int)
signal action_received(action_type: String, payload: Dictionary, tick: int)

var peer: ENetMultiplayerPeer = null
var is_host: bool = false
var local_player_id: int = 1
var connected_peers: Array[int] = []

func host_match(port: int = DEFAULT_PORT) -> Error:
	disconnect_match()
	peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(port, 2) # 2 players max for alley co-op
	if err != OK:
		push_error("Failed to host match on port %d: %d" % [port, err])
		peer = null
		return err

	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	is_host = true
	local_player_id = 1
	connected_peers.clear()
	connected_peers.append(1)
	return OK

func join_match(address: String = "127.0.0.1", port: int = DEFAULT_PORT) -> Error:
	disconnect_match()
	peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(address, port)
	if err != OK:
		push_error("Failed to connect to %s:%d: %d" % [address, port, err])
		peer = null
		return err

	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

	is_host = false
	local_player_id = 2
	connected_peers.clear()
	return OK

func disconnect_match() -> void:
	if peer != null:
		peer.close()
		peer = null
		if multiplayer.has_multiplayer_peer():
			multiplayer.multiplayer_peer = null
	connected_peers.clear()
	is_host = false
	local_player_id = 1

func _on_peer_connected(id: int) -> void:
	if not connected_peers.has(id):
		connected_peers.append(id)
	peer_joined.emit(id)

func _on_peer_disconnected(id: int) -> void:
	connected_peers.erase(id)
	peer_left.emit(id)

func _on_connected_to_server() -> void:
	connected_peers.append(multiplayer.get_unique_id())
	connection_succeeded.emit()

func _on_connection_failed() -> void:
	disconnect_match()
	connection_failed.emit()

func _on_server_disconnected() -> void:
	disconnect_match()
	server_disconnected.emit()

# Host starts match and sends seed/map/mode to client
func broadcast_match_start(seed_val: int, map_id: String, mode: int) -> void:
	if is_host and peer != null:
		rpc("_rpc_start_match", seed_val, map_id, mode)
		match_started.emit(seed_val, map_id, mode)

@rpc("authority", "call_remote", "reliable")
func _rpc_start_match(seed_val: int, map_id: String, mode: int) -> void:
	match_started.emit(seed_val, map_id, mode)

# Send deterministic player action command
func send_action(action_type: String, payload: Dictionary, tick: int) -> void:
	if peer != null and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		rpc("_rpc_action", action_type, payload, tick)
	else:
		# Local dispatch
		action_received.emit(action_type, payload, tick)

@rpc("any_peer", "call_local", "reliable")
func _rpc_action(action_type: String, payload: Dictionary, tick: int) -> void:
	action_received.emit(action_type, payload, tick)
