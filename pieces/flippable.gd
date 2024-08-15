@icon("res://pieces/flippable.png")
class_name Flippable
extends Node2D


@export var flip_on_movement := true
@export var speed_requirement := 10

var prev_position := Vector2()


func _process(delta: float) -> void:
	var movement := global_position.x - prev_position.x
	if flip_on_movement and abs(movement) >= speed_requirement*delta:
		if movement > 0:
			unflip()
		if movement < 0:
			flip()
	
	prev_position = global_position


func flip():
	scale.x = -abs(scale.x)

func unflip():
	scale.x = abs(scale.x)
