@icon("interactable_2d.png")
class_name Interactable2D
extends Node2D


@export var title := "Interactable"
@export var verb := "Interact"
@export var interaction_range := 128.0
@export var tooltip_offset := 64.0
@export var active := true

var current_tooltip = null

const obj_tooltip: PackedScene = preload("res://ui/interactable_tooltip.tscn")

signal activated(player: int)


func _init() -> void:
	add_to_group(&"interactables")

func _process(delta: float) -> void:
	if active and is_nearest_interactable():
		deploy_tooltip()
	else:
		cull_tooltip()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("move_down") and is_valid():
		if Game.is_multiplayer:
			pass
		else:
			activate(event.device)


func is_valid():
	if !active:
		return false
	if !is_nearest_interactable():
		return false
	
	return true

## If player is -1, will check if it's the closest to any player
## Otherwise, will check if it's closest to the specific player
func is_nearest_interactable(player: int = -1, allow_out_of_range: bool = false) -> bool:
	if player >= 0:
		return get_nearest_interactable(player, allow_out_of_range) == self
	else:
		for i in range(PlayerManager.players.size()):
			if get_nearest_interactable(i, allow_out_of_range) == self:
				return true
		
		return false

func get_nearest_interactable(player: int, allow_out_of_range: bool = false):
	if PlayerManager.players.size() <= player:
		return null
	
	var this_player: Player = PlayerManager.players[player].object
	var all_interactables = get_tree().get_nodes_in_group(&"interactables")
	var nearest_interactable: Interactable2D = null
	# Nearest distance squared
	var nearest_d2: float = 100000000000
	
	for i in range( all_interactables.size() ):
		var this_interactable: Interactable2D = all_interactables[i]
		var this_d2: float = this_player.global_position.distance_squared_to( this_interactable.global_position )
		if this_d2 < nearest_d2 and (allow_out_of_range or this_d2 < interaction_range*interaction_range):
			nearest_d2 = this_d2
			nearest_interactable = this_interactable
	return nearest_interactable

func cull_tooltip():
	if is_instance_valid(current_tooltip):
		current_tooltip.queue_free()
	current_tooltip = null

func deploy_tooltip():
	if !is_instance_valid(current_tooltip):
		var new_tooltip = obj_tooltip.instantiate()
		new_tooltip.interactable = self
		Game.deploy_instance(new_tooltip, global_position - Vector2(0, tooltip_offset))
		current_tooltip = new_tooltip

func activate(player: int):
	activated.emit(player)
