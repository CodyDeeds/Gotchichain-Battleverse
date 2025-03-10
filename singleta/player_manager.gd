extends Node

var players: Array[PlayerStats] = []
## Time between a player dying and respawning
var spawn_delay := 3.0
var player_count := 2

const obj_player = preload("res://entities/player.tscn")

signal player_stats_updated
signal player_spawned

func _ready() -> void:
	Events.player_died.connect(_on_player_died)

func start():
	if !Game.is_multiplayer:
		add_players.call_deferred(player_count)

func end():
	players = []

## Adding both players and assigning their addresses
func add_players(count: int):
	for i in range(count):
		add_player(i, 1)
	player_stats_updated.emit()

## Modified add_player method to handle addresses
func add_player(index: int, player_owner: int = 1, address: String = "") -> PlayerStats:
	if index < 0:
		index = players.size() - 1
	var new_player: PlayerStats = get_player(index)
	
	new_player.controller = index
	new_player.name = "Player %s" % (index + 1)
	new_player.multiplayer_owner = player_owner
	
	if address != "":
		new_player.address = address  # Assign the address passed to this function
		print("Address assigned for %s: %s" % [new_player.name, new_player.address])
	else:
		print("Address not provided for player %s, defaulting to empty string." % new_player.name)
	
	spawn_player(index)
	send_player_stats()
	
	if is_instance_valid(new_player.object):
		new_player.object.animation_lock(0.25)
	
	Events.player_added.emit(index)
	
	new_player.money_changed.connect(func(): player_stats_updated.emit())
	
	return new_player

func delayed_spawn(player: int, time: float):
	var timer := get_tree().create_timer(time)
	timer.timeout.connect(spawn_player.bind(player))

## For creating a player object at a random spawn point
func spawn_player(which: int):
	var furthest_spawn = get_furthest_spawn()
	if is_instance_valid(furthest_spawn):
		rpc_spawn_player.bind(which, players[which].multiplayer_owner, furthest_spawn.global_position).rpc()

func get_player(which: int) -> PlayerStats:
	while players.size() < which + 1:
		players.append(PlayerStats.new())
	return players[which]

@rpc("authority", "call_local", "reliable")
func rpc_spawn_player(which: int, player_owner: int, where: Vector2):
	while which >= players.size():
		var new_player_stats := PlayerStats.new()
		new_player_stats.money_changed.connect(func(): player_stats_updated.emit())
		players.append(new_player_stats)
	
	var new_player: Player = obj_player.instantiate()
	if player_owner > 1:
		new_player.name = "player_%s" % player_owner
		new_player.multiplayer_owner = player_owner
	else:
		new_player.name = "player_%s" % which
	new_player.controller = which
	players[which].object = new_player
	players[which].health = new_player.get_health_array()
	new_player.add_wearable(players[which].body_wearable)
	new_player.add_wearable(players[which].head_wearable)
	
	Game.deploy_instance(new_player, where)
	# NEW: Reset the movement state so that the player starts neutral.
	new_player.reset_movement()
	
	player_stats_updated.emit()
	player_spawned.emit()

func get_total_bet() -> int:
	var output: int = 0
	for this_player in players:
		output += this_player.bet
	return output

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
	for i in range(spawn_points.size()):
		var this_spawn: Node2D = spawn_points[i]
		var these_players = get_tree().get_nodes_in_group("players")
		var closest_player_distance: float = 1000000000
		for j in range(these_players.size()):
			var this_player: Player = these_players[j]
			closest_player_distance = min(closest_player_distance, this_player.global_position.distance_to(this_spawn.global_position))
		if closest_player_distance > max_distance:
			max_distance = closest_player_distance
			furthest_spawns = [this_spawn]
		elif closest_player_distance == max_distance:
			furthest_spawns.append(this_spawn)
	return furthest_spawns.pick_random()

func get_player_index(what: Player) -> int:
	for i in range(players.size()):
		if players[i].object == what:
			return i
	return -1

func get_current_player_index() -> int:
	if !Game.is_multiplayer:
		return -1
	for i in range(players.size()):
		if players[i].multiplayer_owner == multiplayer.get_unique_id():
			return i
	return -1

func send_player_stats():
	var these_stats: Array = []
	for i in range(players.size()):
		these_stats.append(players[i].serialise())
	rpc_set_player_stats.bind(these_stats).rpc()

@rpc("authority", "call_remote", "reliable")
func rpc_set_player_stats(what: Array):
	for i in range(what.size()):
		var these_stats: PlayerStats = PlayerStats.deserialise(what[i])
		if i >= players.size():
			players.append(these_stats)
		else:
			players[i] = these_stats
		var object: Player = players[i].object
		object.controller = players[i].controller
		object.multiplayer_owner = players[i].multiplayer_owner
		object.address = players[i].address  # Ensure address is synced
	while players.size() > what.size():
		players.pop_back()
	player_stats_updated.emit()

@rpc("authority", "call_local", "reliable")
func rpc_set_player_health(which: int, health: Array):
	if which < players.size():
		players[which].health = health
	player_stats_updated.emit()

@rpc("authority", "call_local", "reliable")
func rpc_set_player_lives(which: int, lives: Array):
	if which < players.size():
		players[which].lives = lives
	player_stats_updated.emit()

@rpc("authority", "call_local", "reliable")
func rpc_set_player_money(which: int, money: int):
	if which < players.size():
		players[which].money = money
	player_stats_updated.emit()

func attempt_end():
	if !Game.is_multiplayer or is_multiplayer_authority():
		if count_living_players() <= 1:
			Game.rpc_end_game.rpc()

func _on_player_died(which: int):
	if !Game.is_multiplayer or is_multiplayer_authority():
		Game.print_multiplayer("Player %s died" % which)
		var lives: Array = players[which].lives
		lives.pop_back()
		rpc_set_player_lives.bind(which, lives).rpc()
		if lives.size() > 0:
			delayed_spawn(which, spawn_delay)
		else:
			attempt_end()

func _on_player_hp_changed(new_hp: Array, player_id: int):
	if players.size() > player_id:
		players[player_id].health = new_hp.duplicate()
	if Game.is_multiplayer or true:
		rpc_set_player_health.bind(player_id, new_hp).rpc()
	else:
		player_stats_updated.emit()
