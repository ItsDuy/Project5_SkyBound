extends RigidBody3D
@onready var bat_model: Node3D = $bat_model
# @onready var player = get_parent().get_parent().get_node("Player") #Add player's node
var player = null
var last_hit_id: int = -1
@onready var timer: Timer = $Timer
@onready var hurt_sound: AudioStreamPlayer3D = $HurtSound
@onready var dead_sound: AudioStreamPlayer3D = $DeadSound

@onready var sync_timer: Timer = $SyncTimer

signal died
signal died_by(id: int)

var health= 3
var speed= randf_range(2.0,4.0)

var net_position: Vector3
var net_velocity: Vector3

func _ready() -> void:
	if NetworkConnection.is_multiplayer and multiplayer.is_server():
		sync_timer.start()

func _physics_process(delta) -> void:
	player = get_player()
	if player == null: return
	var dir = global_position.direction_to(player.global_position)
	dir.y=0.0
	linear_velocity = dir*speed
		
	
	if NetworkConnection.is_multiplayer:
		if multiplayer.is_server():
			bat_model.rotation.y = Vector3.FORWARD.signed_angle_to(dir, Vector3.UP) + PI

		# CLIENT: interpolate instead of running physics
		else:
			global_position = global_position.lerp(net_position, 0.2)
			linear_velocity = net_velocity
	else:
		bat_model.rotation.y = Vector3.FORWARD.signed_angle_to(dir, Vector3.UP) + PI

func take_damage():
	if player == null: return
	
	if health < 0:
		return
	
	bat_model.hurt()
	hurt_sound.play()
	health-=1
	if health <=0:
		set_physics_process(false)
		gravity_scale= 1.0
		var direction = -1.0 * global_position.direction_to(player.global_position)
		var random_upward_force = Vector3.UP * randf() * 5.0
		apply_central_impulse(direction.rotated(Vector3.UP, randf_range(-0.2, 0.2)) * 10.0 + random_upward_force)
		dead_sound.play()
		timer.start()
		
func take_damage_from(id: int):
	if not is_multiplayer_authority():
		return
	
	last_hit_id = id
	bat_model.hurt()
	hurt_sound.play()
	health-=1
	if health <=0:
		set_physics_process(false)
		gravity_scale= 1.0
		var direction = -1.0 * global_position.direction_to(player.global_position)
		var random_upward_force = Vector3.UP * randf() * 5.0
		apply_central_impulse(direction.rotated(Vector3.UP, randf_range(-0.2, 0.2)) * 10.0 + random_upward_force)
		dead_sound.play()
		timer.start()

func _on_timer_timeout():
	if NetworkConnection.is_multiplayer and multiplayer.is_server():
		_destroy_mob.rpc()

	# Server removes its own mob
	queue_free()
	if NetworkConnection.is_multiplayer:
		died_by.emit(last_hit_id)
	else:
		died.emit()
	
func get_player():
	var players = get_tree().get_nodes_in_group("players")
	if players.size() > 0:
		return players[0]
	return null


func _on_sync_timer_timeout() -> void:
	if multiplayer.is_server():
		_sync_state.rpc(global_transform.origin, linear_velocity)

@rpc("unreliable")
func _sync_state(pos: Vector3, vel: Vector3):
	if multiplayer.is_server():
		return

	net_position = pos
	net_velocity = vel

@rpc("call_local")
func _destroy_mob():
	queue_free()
