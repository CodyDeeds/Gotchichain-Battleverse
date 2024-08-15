extends Node2D


@export var particles: Array[PackedScene] = []


func _ready() -> void:
	for i in particles:
		var new_particles = i.instantiate()
		Game.deploy_instance(new_particles, global_position)
	
	queue_free()
