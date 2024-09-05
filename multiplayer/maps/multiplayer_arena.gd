extends Node2D

@export var map_ui: PackedScene
@onready var UIContainer: CanvasLayer = %UIContainer

func _ready():
	Game.world = self
	
	if !multiplayer.is_server():
		rpc_add_new_player.bind( multiplayer.get_unique_id() ).rpc_id(1)
		var ui = map_ui.instantiate()
		UIContainer.add_child(ui)

func _process(_delta):
	check_player_lives()


@rpc("any_peer", "call_remote", "reliable")
func rpc_add_new_player(peer: int):
	add_player.rpc(peer)

@rpc("authority", "call_local", "reliable")
func add_player(peer: int):
	var new_player: Player = PlayerManager.spawn_player(0, peer)
	Game.print_multiplayer("Arena: Spawned player with owner %s, authority %s. is owner: %s" % [peer, new_player.get_multiplayer_authority(), new_player.is_owner()])

func check_player_lives():
	if multiplayer.is_server():
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
				rpc_id(player["Id"], "end_game_rpc")
				MattohaSystem.Server.RemovePlayerFromLobby(player["Id"])
			call_deferred("queue_free")

@rpc("authority", "call_remote", "reliable")
func end_game_rpc():
	print("Im ending: ", multiplayer.get_unique_id())
	queue_free()
	get_tree().change_scene_to_file("res://ui/end.tscn")
