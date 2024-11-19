extends Node2D


@export var max_volume_speed := 256.0

var previous_height: float = 0


func _ready() -> void:
	for i in range(512):
		for j in [-1, 1]:
			var new_sprite = %sprite.duplicate()
			add_child(new_sprite)
			new_sprite.position.x = 32*i*j
	
	previous_height = global_position.y

func _process(delta: float) -> void:
	var movement := global_position.y - previous_height
	movement /= delta
	var movement_scale := (movement / max_volume_speed)
	movement_scale = clamp(movement_scale, -1, 1)
	if movement_scale > 0:
		%sfx_rising.volume_db = linear_to_db(0)
		%sfx_sinking.volume_db = linear_to_db(movement_scale)
	else:
		%sfx_sinking.volume_db = linear_to_db(0)
		%sfx_rising.volume_db = linear_to_db(-movement_scale)
	
	previous_height = global_position.y
