extends Control

@export var gameholder_scene: PackedScene
@export var qr_scene: PackedScene  # Add this line

func _ready():
	Game.end()
	Game.is_multiplayer = false
	MattohaSystem.Client.ConnectedToServer.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	if (MattohaSystem.IsServerBuild):
		print("server build ...")
		MattohaSystem.StartServer()
		call_deferred("to_placeholder")
	_setup_animation()
	%local.grab_focus()
	%host.visible = OS.is_debug_build()
	#$AnimationPlayer.play("logo_effect")
	#$AnimationPlayer.play("button_effect")
	
	# Set up the tooltips toggle button
	if has_node("%tooltips_toggle"):
		update_tooltip_button_text()
		%tooltips_toggle.pressed.connect(_on_tooltips_toggled)
	
	if OS.has_feature("arcade"):
		enter_arcade_mode()

func _input(event: InputEvent) -> void:
	if OS.has_feature("arcade") and event is InputEventJoypadButton:
		if event.button_index == JOY_BUTTON_START and event.pressed:
			enter_local_game()


func enter_arcade_mode():
	%client.hide()
	%host.hide()
	%local.grab_focus()
	%local.text = "ENTER GAME"
	%no_controller.hide()
	%pc_controls.hide()
	%arcade_controls.show()

func enter_local_game() -> void:
	Game.is_multiplayer = false
	
	if OS.has_feature("arcade"):
		get_tree().change_scene_to_file("res://multiplayer/UI/qr_scene.tscn")  
	else:
		PlayerManager.get_player(0).bet = 2000
		PlayerManager.get_player(1).bet = 2000
		get_tree().change_scene_to_file("res://ui/wearable_selection.tscn")

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

# Update tooltip button text based on its state
func update_tooltip_button_text() -> void:
	if %tooltips_toggle:
		%tooltips_toggle.text = "TOOLTIPS: ON" if Game.show_tooltips else "TOOLTIPS: OFF"

# Called when the tooltips toggle button is pressed
func _on_tooltips_toggled() -> void:
	Game.show_tooltips = !Game.show_tooltips
	update_tooltip_button_text()
	print("Tooltips " + ("enabled" if Game.show_tooltips else "disabled"))
