extends Node

var players: Array[PlayerStats] = []
## Time between a player dying and respawning
var spawn_delay := 3.0
var player_count := 2

const obj_player = preload ("res://entities/player.tscn")

func _ready() -> void:
	Events.player_died.connect(_on_player_died)


func start():
	if !Game.is_multiplayer:
		add_players.call_deferred(player_count)

func end():
	players = []

func add_players(count: int):
	for i in range(count):
		add_player()

## For when a player first joins the game
func add_player(which: int = -1, player_owner: int = 1) -> PlayerStats:
	var new_player: PlayerStats = PlayerStats.new()
	
	new_player.controller = players.size()
	if which >= 0:
		new_player.controller = which
	new_player.name = "Player %s" % (new_player.controller + 1)
	new_player.multiplayer_owner = player_owner
	
	#Game.print_multiplayer("%s added" % new_player.name)
	
	players.append(new_player)
	spawn_player(new_player.controller)
	send_player_stats()
	
	Events.player_added.emit(new_player.controller)
	
	return new_player

func delayed_spawn(player: int, time: float):
	var timer := get_tree().create_timer(time)
	timer.timeout.connect(spawn_player.bind(player))

## For creating a player object at a random spawn point
func spawn_player(which: int):
	var furthest_spawn = get_furthest_spawn()
	if is_instance_valid(furthest_spawn):
		rpc_spawn_player.bind(which, players[which].multiplayer_owner, furthest_spawn.global_position).rpc()

@rpc("authority", "call_local", "reliable")
func rpc_spawn_player(which: int, player_owner: int, where: Vector2):
	#Game.print_multiplayer("Spawning player %s at %s" % [which, where])
	while which >= players.size():
		players.append(PlayerStats.new())
	
	#var player_owner: int = players[which].multiplayer_owner
	var new_player: Player = obj_player.instantiate()
	
	if player_owner > 1:
		new_player.name = "player_%s" % player_owner
		new_player.multiplayer_owner = player_owner
	else:
		new_player.name = "player_%s" % which
	new_player.controller = which
	players[which].object = new_player
	
	Game.deploy_instance(new_player, where)
	
	#Game.print_multiplayer("Player's path is %s" % new_player.get_path())

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
		var these_players = get_tree().get_nodes_in_group("players")
		var closest_player_distance: float = 1000000000
		
		for j in range(these_players.size()):
			var this_player: Player = these_players[j]
			closest_player_distance = min(closest_player_distance, this_player.global_position.distance_to(this_spawn.global_position))
		
		# If this spawn is furthest than any other, reset the list
		if closest_player_distance > max_distance:
			max_distance = closest_player_distance
			furthest_spawns = [this_spawn]
		# If this spawn is the joint furthest, add it to the list
		elif closest_player_distance == max_distance:
			furthest_spawns.append(this_spawn)
	
	return furthest_spawns.pick_random()

func get_player_index(what: Player) -> int:
	for i in range(players.size()):
		if players[i].object == what:
			return i
	return -1

func send_player_stats():
	var these_stats: Array = []
	for i in range(players.size()):
		these_stats.append( players[i].serialise() )
	
	rpc_set_player_stats.bind(these_stats).rpc()

@rpc("authority", "call_remote", "reliable")
func rpc_set_player_stats(what: Array):
	#Game.print_multiplayer("Setting stats to %s" % what)
	for i in range(what.size()):
		var these_stats: PlayerStats = PlayerStats.deserialise( what[i] )
		
		if i >= players.size():
			players.append(these_stats)
		else:
			players[i] = these_stats
		
		var object: Player = players[i].object
		object.controller = players[i].controller
		object.multiplayer_owner = players[i].multiplayer_owner
	
	while players.size() > what.size():
		players.pop_back()

@rpc("authority", "call_local", "reliable")
func rpc_set_player_health(which: int, health: Array):
	if which < players.size():
		players[which].health = health

@rpc("authority", "call_local", "reliable")
func rpc_set_player_lives(which: int, lives: Array):
	if which < players.size():
		players[which].lives = lives


func _on_player_died(which: int):
	if !Game.is_multiplayer or is_multiplayer_authority():
		Game.print_multiplayer("Player %s died" % which)
		
		var lives: Array = players[which].lives
		lives.pop_back()
		rpc_set_player_lives.bind(which, lives).rpc()
		
		if lives.size() > 0:
			delayed_spawn(which, spawn_delay)
		else:
			if count_living_players() == 1:
				get_tree().change_scene_to_file("res://ui/end.tscn")
