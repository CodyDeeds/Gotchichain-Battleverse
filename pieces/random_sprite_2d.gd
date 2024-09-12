@tool
@icon("res://pieces/random_sprite_2d.png")
class_name RandomSprite2D
extends Sprite2D


## If set to 0, will default to [code]hframes * vframes[/code]
@export var total_frames: int = 0


func _ready() -> void:
	roll()


func roll() -> void:
	var frame_count: int = total_frames
	if frame_count <= 0:
		frame_count = hframes * vframes
	
	frame = randi() % frame_count
