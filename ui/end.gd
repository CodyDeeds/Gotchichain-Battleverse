extends Control

const MAIN_SCENE_PATH = "res://multiplayer/UI/main_menu.tscn"

func _ready() -> void:
	if Game.is_multiplayer:
		var these_stats: PlayerStats = PlayerManager.players[ PlayerManager.get_current_player_index() ]
		if these_stats.lives.size() > 0:
			%announcement.text = "You win!"
		else:
			%announcement.text = "You got rekt fren!"
	else:
		%announcement.text = "Player %s is the winner!" % PlayerManager.get_living_players()[0].controller

	# Connect the button signal
	%button.pressed.connect(_on_button_pressed)

func _on_button_pressed() -> void:
	restart_game()

func restart_game():
	log_out()
	get_tree().change_scene_to_file(MAIN_SCENE_PATH)

func log_out():
	var mattoha_client = MattohaSystem.Client
	if mattoha_client:
		mattoha_client.call("LeaveLobby")
		mattoha_client.set("CurrentPlayer", Dictionary())
		mattoha_client.set("CurrentLobby", Dictionary())
		mattoha_client.set("CurrentLobbyPlayers", Dictionary())
		print("Player logged out.")
	else:
		print("MattohaClient instance not found")
