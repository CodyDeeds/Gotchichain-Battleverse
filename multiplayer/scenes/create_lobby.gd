extends Control

@export var lobbyNameInput: LineEdit
@export var GameScene: PackedScene

func _ready():
	MattohaSystem.Client.CreateLobbySucceed.connect(_on_create_lobby_succeed)
	MattohaSystem.Client.CreateLobbyFailed.connect(_on_create_lobby_failed)

func _on_create_lobby_failed(cause: String):
	print("Failed to create lobby: ", cause)

func _on_create_lobby_succeed(_lobby):
	get_tree().change_scene_to_file("res://multiplayer/scenes/lobby.tscn")

func _on_create_lobby_button_pressed():
	var lobby_data = {"Name": lobbyNameInput.text, "MaxPlayers": 4}
	MattohaSystem.Client.CreateLobby(lobby_data, GameScene.resource_path)
