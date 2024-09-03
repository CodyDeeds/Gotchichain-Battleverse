extends Node

var players: Array[PlayerStats] = []
## Time between a player dying and respawning
var spawn_delay := 3.0
var player_count := 2

const obj_player = preload ("res://entities/player.tscn")

func _ready() -> void:
	Events.player_died.connect(_on_player_died)


func start():
	add_players.call_deferred(player_count)

func end():
	players = []

func add_players(count: int):
	for i in range(count):
		add_player()

func add_player():
	var new_player: PlayerStats = PlayerStats.new()
	
	new_player.controller = players.size()
	new_player.name = "Player %s" % (new_player.controller + 1)
	var player_object: Player = spawn_player(new_player.controller)
	if player_object:
		new_player.object = player_object
	
	players.append(new_player)
	
	Events.player_added.emit(new_player.controller)
	
	print("%s added" % new_player.name)

func delayed_spawn(player: int, time: float):
	var timer := get_tree().create_timer(time)
	timer.timeout.connect(spawn_player.bind(player))

func spawn_player(which: int):
	var furthest_spawn = get_furthest_spawn()
	if is_instance_valid(furthest_spawn):
		var new_player = obj_player.instantiate()
		new_player.controller = which
		Game.deploy_instance(new_player, furthest_spawn.global_position)
		return new_player
	return null

func count_living_players() -> int:
	return get_living_players().size()

func get_living_players() -> Array[PlayerStats]:
	var output: Array[PlayerStats] = []

	for this_player in players:
		if this_player.lives.size() > 0:
			output.append(this_player)

	return output

func get_furthest_spawn() -> Node2D:
	var spawn_points = get_tree().get_nodes_in_group("spawn_points")
	
	var max_distance: float = 0
	var furthest_spawns: Array = []
	
	# Roll over each spawn point and judge them
	for i in range(spawn_points.size()):
		var this_spawn: Node2D = spawn_points[i]
		
		# Roll over each player and take note of the closest one
		var players = get_tree().get_nodes_in_group("players")
		var closest_player_distance: float = 1000000000
		
		for j in range(players.size()):
			var this_player: Player = players[j]
			closest_player_distance = min(closest_player_distance, this_player.global_position.distance_to(this_spawn.global_position))
		
		# If this spawn is furthest than any other, reset the list
		if closest_player_distance > max_distance:
			max_distance = closest_player_distance
			furthest_spawns = [this_spawn]
		# If this spawn is the joint furthest, add it to the list
		elif closest_player_distance == max_distance:
			furthest_spawns.append(this_spawn)
	
	return furthest_spawns.pick_random()

func _on_player_died(which: int):
	if Game.is_multiplayer:
		print("A player died in session %s" % multiplayer.get_unique_id())
		if (multiplayer.get_unique_id() != which):
			return
		if (MattohaSystem.Client.CurrentPlayer["lives"].size() > 1):
			MattohaSystem.Client.CurrentPlayer["lives"].pop_front()
			MattohaSystem.Client.SetPlayerData({"lives": MattohaSystem.Client.CurrentPlayer["lives"]})
			delayed_spawn(0, spawn_delay)
		else:
			MattohaSystem.Client.SetPlayerData({"lives": []})
	else:
		print("Player %s died" % which)
		players[which].lives.pop_front()
		if players[which].lives.size() > 0:
			delayed_spawn(which, spawn_delay)
		else:
			if count_living_players() == 1:
				get_tree().change_scene_to_file("res://ui/end.tscn")
