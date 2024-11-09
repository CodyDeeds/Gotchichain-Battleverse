@icon("res://pieces/parallaxor.png")
class_name Parallaxor
extends Node2D


## Amount that this layer follows the camera. Actual movement, not apparent movement. So 1 follows the camera exactly with no apparent movement
## where 0 stays still and appears attached to the foreground
@export var move_scale := Vector2(1, 1)
## Amount that this layer's position is offset before [code]move_scale[/code] is applied
@export var offset := Vector2()
## Amount that this layer's scaling follows the zoom level of the camera
@export var scale_scale := 1.0
## Limits within which this layer must stay relative to the camera. An empty rect imposes no limits
@export var limits: Rect2 = Rect2()
## Minimum scale allowed
@export var scale_min: float = 0.0
## Maximum scale allowed
@export var scale_max: float = 2.0

var cam: Camera2D = null


func _process(_delta: float) -> void:
	if !is_instance_valid(cam):
		identify_camera()
	reposition()


func identify_camera():
	cam = get_viewport().get_camera_2d()

func reposition():
	if is_instance_valid(cam):
		var modified_zoom: Vector2 = Vector2(1, 1).lerp(cam.zoom, scale_scale)
		global_scale = Vector2(1, 1) / (modified_zoom)
		global_position = (cam.global_position) * move_scale
		global_position += (offset * global_scale) * (Vector2(1, 1) - move_scale)
		
		if limits != Rect2():
			var relative_position: Vector2 = cam.global_position - global_position
			
			if relative_position.x < limits.position.x:
				global_position.x += (limits.position.x - relative_position.x)
			if relative_position.y < limits.position.y:
				global_position.y += (limits.position.y - relative_position.y)
			
			if relative_position.x > limits.end.x:
				global_position.x += (limits.end.x - relative_position.x)
			if relative_position.y > limits.end.y:
				global_position.y += (limits.end.y - relative_position.y)
