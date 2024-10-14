extends Node2D


## Speed with which the item is thrown out of the chest on opening
@export var item_jump_speed: float = 500.0
## Item will be thrown upward plus or minus this random angle value in degrees
@export var item_random_angle: float = 30.0

@export var cost: int = 1000


func _ready() -> void:
	show_cost()


func deploy_item(player: int = 0):
	if PlayerManager.players.size() > player:
		# Place this item into the player's hand
		var player_object: Player = PlayerManager.players[player].object
		player_object.spawn_item(BigData.get_random_item_from_pool(Item.POOLS.CHEST))
	else:
		# If there's no player, chuck the item at a suitably amusing speed
		var this_item: PackedScene = BigData.get_random_item_from_pool(Item.POOLS.CHEST)
		var new_item: Item = Game.create_instance(this_item)
		Game.deploy_instance(new_item, global_position)
		var impulse: Vector2 = Vector2(0, -item_jump_speed)
		impulse = impulse.rotated( deg_to_rad(randf_range(-item_random_angle, item_random_angle)) )
		new_item.apply_central_impulse(impulse)

func show_cost():
	%cost.text = "[center][wave]$%s[/wave][/center]" % cost

func open():
	%sprite.frame = 1
	%interactable.active = false

func close():
	%sprite.frame = 0
	%interactable.active = true


func _on_interactable_activated(player: int) -> void:
	if PlayerManager.players.size() > player:
		var available_money: int = PlayerManager.players[player].money
		if available_money >= cost:
			PlayerManager.players[player].money -= cost
			open()
			deploy_item(player)
			%timer.start()


func _on_timer_timeout() -> void:
	close()
