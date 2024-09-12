extends Node2D

@export var map_ui: PackedScene
@export var force_map: String = ""

@onready var UIContainer: CanvasLayer = %UIContainer

var current_map_name: String = ""

func _ready():
	Game.world = self
	
	# If this is a client, request the addition of a new player object
	if Game.is_multiplayer and !multiplayer.is_server():
		request_map()
		rpc_add_new_player.bind( multiplayer.get_unique_id() ).rpc_id(1)
	else:
		deploy_random_map()
	
	var ui = map_ui.instantiate()
	UIContainer.add_child(ui)


func deploy_random_map():
	var map_resources = BigData.maps.load_all()
	var this_map = map_resources.pick_random() as MapData
	current_map_name = this_map.name
	
	if OS.is_debug_build() and BigData.get_map_from_name(force_map) != null:
		print("Deploying %s" % force_map)
		rpc_deploy_map_by_name.bind(force_map).rpc()
	else:
		rpc_deploy_map_by_name.bind(this_map.name).rpc()

func request_map():
	rpc_send_current_map.bind( multiplayer.get_unique_id() ).rpc()

## Gets the client in question to spawn the relevant map ID
@rpc("any_peer", "call_local", "reliable")
func rpc_send_current_map(peer: int):
	rpc_deploy_map_by_name.bind(current_map_name).rpc_id(peer)

@rpc("authority", "call_local", "reliable")
func rpc_deploy_map_by_name(what: String):
	var this_map: MapData = BigData.get_map_from_name(what)
	Game.map = this_map.scene
	deploy_map(this_map.scene)

func deploy_map(what: PackedScene):
	var new_map = what.instantiate()
	%map.add_child(new_map)


@rpc("any_peer", "call_remote", "reliable")
func rpc_add_new_player(peer: int):
	#add_player.rpc(peer)
	var new_player: PlayerStats = PlayerManager.add_player(0, peer)
	Game.print_multiplayer("Arena: Spawned player with owner %s, authority %s. is owner: %s" % [peer, new_player.multiplayer_owner, new_player.object.is_owner()])

@rpc("authority", "call_local", "reliable")
func add_player(peer: int):
	var new_player: PlayerStats = PlayerManager.add_player(0, peer)
	Game.print_multiplayer("Arena: Spawned player with owner %s, authority %s. is owner: %s" % [peer, new_player.multiplayer_owner, new_player.object.is_owner()])

func check_player_lives():
	if Game.is_multiplayer and multiplayer.is_server():
		var lobby_id = MattohaSystem.ExtractLobbyId(self.get_path())
		var players = MattohaSystem.Server.GetLobbyPlayers(lobby_id)
		var should_end = false
		for player in players:
			if "lives" not in player:
				continue
			if (player["lives"].size() == 0):
				should_end = true
				break
		if (should_end):
			print("Should end")
			for player in players:
				end_game_rpc.rpc_id(player["Id"])
				MattohaSystem.Server.RemovePlayerFromLobby(player["Id"])
			call_deferred("queue_free")

@rpc("authority", "call_remote", "reliable")
func end_game_rpc():
	print("Im ending: ", multiplayer.get_unique_id())
	queue_free()
	get_tree().change_scene_to_file("res://ui/end.tscn")
