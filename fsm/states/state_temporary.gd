@tool
class_name TemporaryState
extends State


@export var duration := 1.0

signal complete


func _init():
	auto_proceed = false

func _step(delta: float):
	super._step(delta)
	
	if age >= duration and duration >= 0:
		complete.emit()
		enter_next_state()
