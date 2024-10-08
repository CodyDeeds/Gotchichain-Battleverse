extends Node

var gameholder: Control = null
var world: Node2D = null
var ui: Control = null
var cam: Camera2D = null
var map: PackedScene = null
var afoot := false
var is_multiplayer: bool = false

func _ready() -> void:
	if !OS.is_debug_build():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE:
			get_tree().quit()
		if OS.is_debug_build() and event.keycode == KEY_F4 and event.pressed:
			if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN or DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func start():
	if !afoot:
		PlayerManager.start()
		afoot = true

func end():
	if afoot:
		PlayerManager.end()
		
		multiplayer.multiplayer_peer.close()
		MattohaSystem.Server.Players = {}
		MattohaSystem.Server.Lobbies = {}
		MattohaSystem.Server.SpawnedNodes = {}
		MattohaSystem.Server.RemovedSceneNodes = {}
		afoot = false

func return_to_menu():
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")

func create_instance(what: PackedScene):
	if multiplayer:
		return MattohaSystem.CreateInstance(what.resource_path)
	else:
		return what.instantiate()

func deploy_instance(what: Node2D, where: Vector2):
	if is_instance_valid(world):
		what.position = where
		world.add_child(what)
	else:
		push_error("Attempting to deploy %s at %s, but no world exists" % [what, where])

func deploy_ui_instance(what: Control, where: Vector2):
	if is_instance_valid(ui):
		what.position = where
		ui.add_child(what)

func call_server(what: Callable):
	if is_multiplayer:
		what.rpc_id(1)
	else:
		what.call()

func print_multiplayer(what: String):
	if is_multiplayer:
		print("Session %s: %s" % [multiplayer.get_unique_id(), what])
	else:
		print("Local game: %s" % what)

@rpc("authority", "call_local", "reliable")
func rpc_end_game():
	get_tree().change_scene_to_file("res://ui/end.tscn")
