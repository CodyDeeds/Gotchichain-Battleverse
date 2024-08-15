class_name Spawner
extends Node2D


@export var scene: PackedScene
@export var auto_activate: bool = false


func _ready() -> void:
	if auto_activate:
		activate()


func activate():
	var new_scene := scene.instantiate()
	Game.deploy_instance(new_scene, global_position)
