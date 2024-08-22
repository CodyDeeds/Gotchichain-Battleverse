extends Node2D

@export var map_ui: PackedScene
@onready var UIContainer: CanvasLayer = %UIContainer

func _ready():
	Game.world = self
	
	if (!multiplayer.is_server()):
		PlayerManager.spawn_player()
		var ui = map_ui.instantiate()
		UIContainer.add_child(ui)

func _process(_delta):
	check_player_lives()

func check_player_lives():
	if (multiplayer.is_server()):
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
