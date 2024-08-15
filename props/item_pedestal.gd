extends Node2D

@export var items: Array[PackedScene] = []
@export var item_jump_speed := 200.0

var current_item: Item = null

func _ready():
	if (multiplayer.is_server()):
		$spawn_timer.start()

func spawn_item():
	var this_item = items.pick_random()
	var new_item: Item = MattohaSystem.CreateInstance(this_item.resource_path)
	new_item.global_position = position
	MattohaSystem.GetLobbyNodeFor(self).add_child(new_item)
	new_item.apply_central_impulse(Vector2(0, -item_jump_speed))
	new_item.tree_exiting.connect(_on_item_slain)
	current_item = new_item

func _on_spawn_timer_timeout() -> void:
	spawn_item()

func _on_item_slain():
	current_item = null
	if (multiplayer.is_server()):
		$spawn_timer.start()
