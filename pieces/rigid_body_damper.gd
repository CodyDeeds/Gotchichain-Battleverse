extends Node


@export var friction := 10.0
@export var active := true

var father: RigidBody2D = null


func _process(delta: float) -> void:
	if is_instance_valid(father):
		if active:
			father.apply_central_impulse(-father.linear_velocity * friction * delta)
	else:
		if get_parent() is RigidBody2D:
			father = get_parent()
