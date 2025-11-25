extends RigidBody3D
@onready var bat_model: Node3D = $bat_model

func _physics_process(delta) -> void:
	pass
	
func take_damage():
	bat_model.hurt()
