extends Node2D

## Speed with which items jump when they appear from this pedestal
@export var item_jump_speed := 200.0
## If set, this item will always spawn from this pedestal. If not, will randomly select from [code]items[/code]
@export var force_item: PackedScene = null

var current_item: Item = null

func _ready():
	if (multiplayer.is_server()):
		$spawn_timer.start()

func spawn_item():
	var this_item: PackedScene
	if force_item:
		this_item = force_item
	else:
		this_item = BigData.get_random_item_from_pool(Item.POOLS.PEDESTAL)
	#var new_item: Item = MattohaSystem.CreateInstance(this_item.resource_path)
	var new_item: Item = Game.create_instance(this_item)
	#new_item.global_position = position
	#MattohaSystem.GetLobbyNodeFor(self).add_child(new_item)
	Game.deploy_instance(new_item, position)
	new_item.apply_central_impulse(Vector2(0, -item_jump_speed))
	new_item.tree_exiting.connect(_on_item_slain)
	current_item = new_item

func _on_spawn_timer_timeout() -> void:
	spawn_item()

func _on_item_slain():
	current_item = null
	if (multiplayer.is_server()):
		$spawn_timer.start()
