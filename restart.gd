extends Node

const MAIN_SCENE_PATH = "res://multiplayer/UI/main_menu.tscn"

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R and Input.is_key_pressed(KEY_CTRL):
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
