extends Control

@export var lives_list1: LivesList
@export var lives_list2: LivesList

func _ready():
	MattohaSystem.Client.SetPlayerDataSucceed.connect(on_player_update)
	MattohaSystem.Client.JoinedPlayerUpdated.connect(on_joined_player_update)
	update_lives()

func on_player_update(_new_data: Dictionary):
	update_lives()

func on_joined_player_update(_player: Dictionary):
	update_lives()

func update_lives():
	var my_lives = []
	var other_lives = []

	for player in MattohaSystem.Client.CurrentLobbyPlayers.values():
		if player["Id"] == multiplayer.get_unique_id():
			if ("lives" in player):
				my_lives = player["lives"]
		else:
			if ("lives" in player):
				other_lives = player["lives"]

	lives_list1.update_lives(my_lives)
	lives_list2.update_lives(other_lives)
