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
		var new_player: Player = spawn_player()
		if !Game.is_multiplayer:
			new_player.controller = i

func delayed_spawn(time: float):
	var timer := get_tree().create_timer(time)
	timer.timeout.connect(spawn_player.bind())

func spawn_player():
	var new_player: Player = Game.create_instance( obj_player )
	#var instance = MattohaSystem.CreateInstance("res://entities/player.tscn") as Node2D
	var farthest_spawn = PlayerManager.get_furthest_spawn()
	#new_player.global_position = farthest_spawn.global_position
	#MattohaSystem.Client.LobbyNode.add_child(instance)
	Game.deploy_instance(new_player, farthest_spawn.global_position)
	return new_player

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
	return spawn_points.pick_random()

func _on_player_died(which: int):
	print("Player %s died" % which)
	if (multiplayer.get_unique_id() != which):
		return
	if (MattohaSystem.Client.CurrentPlayer["lives"].size() > 1):
		MattohaSystem.Client.CurrentPlayer["lives"].pop_front()
		MattohaSystem.Client.SetPlayerData({"lives": MattohaSystem.Client.CurrentPlayer["lives"]})
		delayed_spawn(spawn_delay)
	else:
		MattohaSystem.Client.SetPlayerData({"lives": []})
