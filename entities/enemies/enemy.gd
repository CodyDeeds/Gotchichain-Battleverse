class_name Enemy
extends Entity


func _ready() -> void:
	super()
	
	collision_layer = 64
	collision_mask = 5
