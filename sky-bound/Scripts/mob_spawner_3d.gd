extends Node3D
signal mob_spawned(mob)
signal boss_mob_spawned(mob)
@export var mob_to_spawn: PackedScene =null
@export var boss_mob_to_spawn: PackedScene =null
@onready var marker_3d: Marker3D = $Marker3D
@onready var timer: Timer = $Timer
@onready var timer_2: Timer = $Timer2



func _on_timer_timeout():
	if not NetworkConnection.is_multiplayer:
		spawn_mob()
		return
	elif multiplayer.is_server():
		var new_mob = spawn_mob()
		var mob_id = str(Time.get_ticks_msec()) + "_" + str(randi())
		new_mob.name = mob_id
		_spawn_mob_rpc.rpc(mob_id, new_mob.global_position)
		

func spawn_mob():
	var new_mob = mob_to_spawn.instantiate()
	add_child(new_mob)
	new_mob.global_position = marker_3d.global_position
	mob_spawned.emit(new_mob)
	var new_boss_mob=boss_mob_to_spawn.instantiate()
	add_child(new_boss_mob)
	new_boss_mob.global_position=marker_3d.global_position
	boss_mob_spawned.emit(new_boss_mob)
	



func _on_timer_2_timeout() -> void:
	var new_boss_mob=boss_mob_to_spawn.instantiate()
	add_child(new_boss_mob)
	new_boss_mob.global_position=marker_3d.global_position
	boss_mob_spawned.emit(new_boss_mob)
	return new_mob
	
@rpc("call_local", "any_peer")
func _spawn_mob_rpc(mob_id: String, pos: Vector3):
	if !is_inside_tree():
		call_deferred("_spawn_mob_rpc", mob_id, pos)
		return
	if multiplayer.is_server():
		return

	var mob = mob_to_spawn.instantiate()
	mob.name = mob_id
	mob.global_position = pos
	add_child(mob)
	mob_spawned.emit(mob)
