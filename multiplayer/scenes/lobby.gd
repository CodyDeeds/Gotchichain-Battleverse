extends Control

@export var PlayersLabel: Label

func _ready():
	MattohaSystem.Client.LoadLobbyPlayersSucceed.connect(_on_load_players)
	MattohaSystem.Client.NewPlayerJoined.connect(_on_new_player_joined)
	MattohaSystem.Client.PlayerLeft.connect(_on_player_left)
	MattohaSystem.Client.StartGameSucceed.connect(_on_start_game)

	MattohaSystem.Client.LoadLobbyPlayers()
	refresh_players_label()
	
	%button.grab_focus()

func refresh_players_label():
	var players_count = MattohaSystem.Client.CurrentLobbyPlayers.size()
	PlayersLabel.text = "Joined Players: %d" % players_count

func _on_new_player_joined(_player):
	refresh_players_label()

func _on_player_left(_player):
	refresh_players_label()

func _on_load_players(_players):
	refresh_players_label()

func _on_button_pressed():
	MattohaSystem.Client.StartGame()

func _on_start_game(_lobby):
	get_tree().change_scene_to_file("res://multiplayer/scenes/game_holder.tscn")
