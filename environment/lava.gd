extends Node2D


func _ready() -> void:
	for i in range(512):
		for j in [-1, 1]:
			var new_sprite = %sprite.duplicate()
			add_child(new_sprite)
			new_sprite.position.x = 32*i*j
