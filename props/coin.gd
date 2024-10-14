extends RigidBody2D


var value: int = 100


func _ready() -> void:
	apply_central_impulse( Vector2(0, randf_range(-600, -100)).rotated(randf_range(-.5, .5)) )
	%sprite.actual_frame = randf()*8

func _on_player_detector_player_entered() -> void:
	var player: Player = Util.get_nearest_group_member(&"players", global_position)
	if is_instance_valid(player):
		var id: int = player.get_id()
		if PlayerManager.players.size() > id:
			PlayerManager.players[id].money += value
	
	queue_free()
