extends Node


@export var gameholder_scene: PackedScene
@export var maps: ResourceGroup = null

var game_scene: PackedScene = null


func _ready() -> void:
	var map_resources = maps.load_all()
	var this_map: MapData
	this_map = map_resources.pick_random()
	game_scene = this_map.scene
	
	activate.call_deferred()

func activate() -> void:
	get_tree().change_scene_to_packed(gameholder_scene)
	Game.map = game_scene

