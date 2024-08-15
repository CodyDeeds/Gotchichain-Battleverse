extends Control

func _ready():
	MattohaSystem.Client.ConnectedToServer.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	if (MattohaSystem.IsServerBuild):
		print("server build ...")
		MattohaSystem.StartServer()
		call_deferred("to_placeholder")
	_setup_animation()
	$AnimationPlayer.play("logo_effect")
	$AnimationPlayer.play("button_effect")

func to_placeholder():
	get_tree().change_scene_to_file("res://multiplayer/scenes/game_holder.tscn")

func _on_server_button_pressed():
	MattohaSystem.StartServer()
	call_deferred("to_placeholder")

func _on_client_button_pressed():
	MattohaSystem.StartClient()

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
