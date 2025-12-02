extends Node

signal connected

const IP_ADDR = "localhost"
const PORT = 42069

var peer: ENetMultiplayerPeer
var is_multiplayer := false

func start_server() -> void:
	is_multiplayer = true
	peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT, 4)
	multiplayer.multiplayer_peer = peer
	
func start_client() -> void:
	is_multiplayer = true
	peer = ENetMultiplayerPeer.new()
	peer.create_client(IP_ADDR, PORT)
	multiplayer.multiplayer_peer = peer 
	get_tree().multiplayer.connected_to_server.connect(_on_connected)
	
func _on_connected():
	emit_signal("connected")	
