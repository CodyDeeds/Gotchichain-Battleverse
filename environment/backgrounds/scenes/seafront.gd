extends Node2D


@export var scroll_speed: float = 8


func _process(delta: float) -> void:
	var layers = [%clouds, %boats0, %boats1, %boats2]
	for this_layer in layers:
		this_layer.offset.x -= scroll_speed*delta
