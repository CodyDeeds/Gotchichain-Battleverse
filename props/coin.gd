extends RigidBody2D


var value: int = 100

const fx_scene = preload("res://fx/coin_collect.tscn")


func _init() -> void:
	add_to_group(&"coins")

func _ready() -> void:
	apply_central_impulse( Vector2(0, randf_range(-600, -100)).rotated(randf_range(-.5, .5)) )
	%sprite.actual_frame = randf()*8


func change_scale(what: float):
	var this_scale: Vector2 = Vector2(what, what)
	%shape.scale = this_scale
	%sprite.scale = this_scale
	%player_detector.scale = this_scale

func awaken_nearby_coins():
	var awaken_range: float = 64
	for this_coin in get_tree().get_nodes_in_group(&"coins"):
		if global_position.distance_squared_to(this_coin.global_position) < awaken_range*awaken_range:
			this_coin.sleeping = false


func _on_player_detector_player_entered() -> void:
	var player: Player = Util.get_nearest_group_member(&"players", global_position)
	if is_instance_valid(player):
		var id: int = player.get_id()
		if PlayerManager.players.size() > id:
			PlayerManager.players[id].money += value
	
	var new_fx = fx_scene.instantiate()
	Game.deploy_instance(new_fx, global_position)
	new_fx.scale = scale
	
	awaken_nearby_coins()
	queue_free()
