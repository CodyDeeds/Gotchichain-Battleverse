class_name SFXController
extends Node


@export var stream: AudioStream = null
@export var transient: bool = true


func _ready() -> void:
	activate()


func activate():
	var father = get_parent()
	if father is AudioStreamPlayer or father is AudioStreamPlayer2D or father is AudioStreamPlayer3D:
		father.stream = stream
		father.finished.connect(_on_finished)


func _on_finished():
	var father = get_parent()
	if transient:
		father.stop()
		father.queue_free()
