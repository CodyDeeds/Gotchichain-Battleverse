extends Control

@export var LobbiesContainer: VBoxContainer
@export var LobbySlot = preload ("res://multiplayer/UI/slots/lobby_slot.tscn")

func _ready():
	MattohaSystem.Client.LoadAvailableLobbiesSucceed.connect(_on_load_available_lobbies_succeed)
	MattohaSystem.Client.JoinLobbySucceed.connect(_on_join_lobby)
	MattohaSystem.Client.LoadAvailableLobbies()

func _on_load_available_lobbies_succeed(lobbies):
	for slot in LobbiesContainer.get_children():
		slot.queue_free()
	for lobby in lobbies:
		var lobby_slot = LobbySlot.instantiate()
		lobby_slot.lobby_dict = lobby
		LobbiesContainer.add_child(lobby_slot)

func _on_create_lobby_button_pressed():
	get_tree().change_scene_to_file("res://multiplayer/scenes/create_lobby.tscn")

func _on_join_lobby(lobby):
	if (lobby["IsGameStarted"]):
		get_tree().change_scene_to_file("res://multiplayer/scenes/game_holder.tscn")
	else:
		get_tree().change_scene_to_file("res://multiplayer/scenes/lobby.tscn")
