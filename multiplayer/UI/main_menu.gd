extends Control

@export var gameholder_scene: PackedScene

func _ready():
	PlayerManager.end()
	Game.is_multiplayer = false
	MattohaSystem.Client.ConnectedToServer.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	if (MattohaSystem.IsServerBuild):
		print("server build ...")
		MattohaSystem.StartServer()
		call_deferred("to_placeholder")
	_setup_animation()
	%client.grab_focus()
	#$AnimationPlayer.play("logo_effect")
	#$AnimationPlayer.play("button_effect")



func enter_local_game() -> void:
	Game.is_multiplayer = false
	#var map_resources = BigData.maps.load_all()
	#var this_map: MapData
	#this_map = map_resources.pick_random()
	#var game_scene = this_map.scene
	
	get_tree().change_scene_to_packed(gameholder_scene)
	#get_tree().change_scene_to_file("res://multiplayer/scenes/game_holder.tscn")
	#Game.map = game_scene

func to_placeholder():
	Game.is_multiplayer = true
	get_tree().change_scene_to_file("res://multiplayer/scenes/game_holder.tscn")

func _on_server_button_pressed():
	MattohaSystem.StartServer()
	call_deferred("to_placeholder")

func _on_client_button_pressed():
	Game.is_multiplayer = true
	MattohaSystem.StartClient()

func _on_local_pressed() -> void:
	enter_local_game()

func _on_host_pressed() -> void:
	MattohaSystem.StartServer()
	to_placeholder()

func _on_connected():
	MattohaSystem.Client.SetPlayerData({"lives": [0, 0, 0]})
	get_tree().change_scene_to_file("res://multiplayer/scenes/lobbies.tscn")

func _on_connection_failed():
	print("Connection failed as client")

func _setup_animation():
	var animated_sprite = $AnimatedSprite
	var sprite_frames = SpriteFrames.new()
	for i in range(1, 9):
		sprite_frames.add_frame("default", load("res://multiplayer/UI/Gotchi-" + str(i) + ".png"))
	animated_sprite.frames = sprite_frames
	animated_sprite.play()


