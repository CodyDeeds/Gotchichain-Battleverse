extends Enemy


var armed: bool = true
var spawn_position: Vector2 = Vector2()


func _ready() -> void:
	super()
	
	spawn_position = global_position

func _process(delta: float) -> void:
	super(delta)
	
	global_position = global_position.lerp(spawn_position, 5*delta)


func attack():
	if armed and %player_detector.overlapping_players.size() > 0:
		var this_player: Player = %player_detector.overlapping_players[0]
		if this_player.global_position.x < global_position.x:
			%flippable.scale.x = -1
		if this_player.global_position.x > global_position.x:
			%flippable.scale.x = 1
		
		%animator.play(&"attacc")
		
		armed = false
		var timer: SceneTreeTimer = get_tree().create_timer(2)
		timer.timeout.connect(func(): armed = true)

func activate_hitbox():
	%hitbox.active = true
	var timer: SceneTreeTimer = get_tree().create_timer(.1)
	timer.timeout.connect(func(): %hitbox.active = false)


func _on_player_detector_player_within() -> void:
	attack()
