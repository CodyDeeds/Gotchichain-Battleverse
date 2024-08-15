@icon("res://pieces/parallaxor.png")
class_name Parallaxor
extends Node2D


@export var move_scale := Vector2(1, 1)

var cam: Camera2D = null


func _process(delta: float) -> void:
	if !is_instance_valid(cam):
		identify_camera()
	reposition()


func identify_camera():
	cam = get_viewport().get_camera_2d()

func reposition():
	if is_instance_valid(cam):
		global_position = cam.global_position * move_scale
