class_name Spawner
extends Node2D


## The scene to spawn
@export var scene: PackedScene
## Whether to activate the spawner immediately on loading
@export var auto_activate: bool = false
## Whether to spawn the scene as a sibling of this spawner
@export var spawn_as_sibling: bool = false
## If true, this spawner self-destructs after use
@export var one_shot: bool = false
## Whether the objects created are intended to be synced onlihne
@export var sync_spawns: bool = false
## Where to spawn the thing relative to this node in global space
@export var offset: Vector2 = Vector2()


func _ready() -> void:
	if auto_activate:
		activate.call_deferred()


func activate():
	var new_scene
	if sync_spawns:
		new_scene = Game.create_instance(scene)
	else:
		new_scene = scene.instantiate()
	
	if spawn_as_sibling:
		get_parent().add_child(new_scene)
		new_scene.global_position = global_position + offset
		new_scene.global_scale = global_scale
	else:
		Game.deploy_instance(new_scene, global_position + offset)
		new_scene.global_scale = global_scale
	
	if one_shot:
		queue_free()
	
	return new_scene
