extends Area3D

const SPEED = 30.0
const RANGE = 60.0

var travelled_distance = 0.0
@export var shooter_id: int = -1

func _physics_process(delta: float) -> void:
	position += transform.basis.z * SPEED * delta
	travelled_distance += SPEED * delta
	
	if travelled_distance > RANGE:
		queue_free()


func _on_body_entered(body: Node3D) -> void:
	if body.has_method("take_damage"):
		if shooter_id >= 0:
			body.take_damage_from(shooter_id)
		else:
			body.take_damage()
		
	queue_free()
