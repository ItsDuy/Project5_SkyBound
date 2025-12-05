extends MultiplayerSpawner

@export var network_player: PackedScene

func _ready() -> void:
	await get_tree().process_frame
	_initialize_spawner()

func _initialize_spawner() -> void:
	# single mode
	print("[SPAWNER] _ready - network_player =", network_player)
	print("[SPAWNER] is_multiplayer =", NetworkConnection.is_multiplayer)
	print("[SPAWNER] multiplayer_peer exists =", multiplayer.multiplayer_peer != null)
	
	if multiplayer.multiplayer_peer:
		print("[SPAWNER] multiplayer.is_server() =", multiplayer.is_server())
		print("[SPAWNER] get_unique_id() =", multiplayer.get_unique_id())
	else:
		print("[SPAWNER] NO MULTIPLAYER PEER - waiting...")
		await get_tree().create_timer(0.1).timeout
		if multiplayer.multiplayer_peer:
			print("[SPAWNER] Multiplayer peer found after delay")
		else:
			print("[SPAWNER] Still no multiplayer peer!")
			return
	
	if  NetworkConnection.is_multiplayer == false:
		print("[SPAWNER] Running in Single Player mode")
		_spawn_single_player()
		return
	
	# multi mode
	if multiplayer.is_server():
		print("[SPAWNER] Server mode - connecting signals")
		multiplayer.peer_connected.connect(_on_peer_connected_spawn)
		var server_id = multiplayer.get_unique_id()
		print("[SPAWNER] Server unique_id =", server_id, " - Server will observe only, no player spawn")
		
		rpc("_request_client_id")
		
		for peer_id in multiplayer.get_peers():
			print("[SPAWNER] Spawning peer from get_peers(): ", peer_id)
			spawn_player(peer_id)
	else:
		var client_id = multiplayer.get_unique_id()
		print("[SPAWNER] Client mode - unique_id =", client_id)
		rpc_id(1, "_receive_client_id", client_id)

func _on_peer_connected_spawn(id: int) -> void:
	rpc_id(id, "_request_client_id")

@rpc("any_peer", "call_local", "unreliable")
func _request_client_id() -> void:
	if !multiplayer.is_server():
		rpc_id(1, "_receive_client_id", multiplayer.get_unique_id())

@rpc("any_peer", "call_local", "unreliable")
func _receive_client_id(client_unique_id: int) -> void:
	if !multiplayer.is_server():
		return
	print("[SPAWNER] Received client unique_id: ", client_unique_id)
	spawn_player(client_unique_id)
	
var spawned_players: = {} 

func spawn_player(id: int) -> void:
	print("[SPAWNER] spawn_player called with ID: ", id)
	print("[SPAWNER] is_server() =", multiplayer.is_server())
	
	if !multiplayer.is_server():
		print("[SPAWNER] Not server, returning")
		return
	
	# Don't spawn player for server (server only observes)
	var server_id = multiplayer.get_unique_id()
	if id == server_id:
		print("[SPAWNER] Skipping spawn for server (observer mode)")
		return
	
	if network_player == null:
		print("[SPAWNER] ERROR: network_player is null!")
		return
	
	# Tránh spawn duplicate
	if spawned_players.has(id):
		print("[SPAWNER] Player with ID ", id, " already spawned, skipping")
		return
	
	print("[SPAWNER] Spawning player with ID: ", id, " (type: ", typeof(id), ")")
	var player: Node = network_player.instantiate()
	if player == null:
		print("[SPAWNER] ERROR: Failed to instantiate player!")
		return
	
	player.name = str(id)
	
	var spawn_point := $"../SpawnPoint"
	if spawn_point == null:
		print("[SPAWNER] ERROR: SpawnPoint not found!")
		return
		
	player.global_position = spawn_point.global_position
	player.set_multiplayer_authority(id)
	
	print("[SPAWNER] Player spawned with name: ", player.name, ", authority: ", id)
	spawned_players[id] = true
	
	var spawn_path_node = get_node(spawn_path)
	if spawn_path_node == null:
		print("[SPAWNER] ERROR: spawn_path node not found: ", spawn_path)
		return
		
	print("[SPAWNER] Adding player to: ", spawn_path)
	spawn_path_node.call_deferred("add_child", player)
	
func _spawn_single_player():
	var player: Node = network_player.instantiate()
	player.name = "1"
	
	var spawn_point := $"../SpawnPoint"
	player.global_position = spawn_point.global_position
	player.set_multiplayer_authority(1)
	get_node(spawn_path).call_deferred("add_child", player)
