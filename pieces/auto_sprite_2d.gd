@icon("res://pieces/auto_sprite_2d.png")
class_name AutoSprite2D
extends Sprite2D


@export var animation_speed: float = 10.0
var has_set_actual_frame: bool = false
var actual_frame: float = 0.0: set = set_actual_frame

signal finished


func _ready() -> void:
	if !has_set_actual_frame:
		actual_frame = frame

func _process(delta: float) -> void:
	actual_frame += animation_speed * delta
	if actual_frame >= hframes*vframes or actual_frame < 0:
		emit_signal("finished")
	actual_frame = fposmod(actual_frame, hframes*vframes)
	frame = int(actual_frame)


func set_actual_frame(what: float):
	actual_frame = what
	has_set_actual_frame = true
