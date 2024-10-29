@tool
class_name RotationRandomiser
extends Node



var prev_position: Vector2


func _ready() -> void:
	var father: Node2D = get_parent() as Node2D
	father.rotation = randf() * 2*PI
