@icon("res://pieces/camera_shaker.png")
class_name CameraShaker
extends Node


@export_group("Conditions")
@export var auto_activate: bool = false
@export var one_shot: bool = false
@export_group("Shake")
@export var amount: float = 16
@export var random_direction: bool = true
@export var direction: float = 0


func _ready() -> void:
	if auto_activate:
		activate()


func activate():
	if is_instance_valid(Game.cam):
		if random_direction:
			Game.cam.shake(amount)
		else:
			Game.cam.shake(amount, direction)
	
	if one_shot:
		queue_free()
