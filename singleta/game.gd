extends Node

var gameholder: Control = null
var world: Node2D = null
var ui: Control = null
var cam: Camera2D = null
var map: PackedScene = null
var afoot := false

func _ready() -> void:
	# DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	pass

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE:
			get_tree().quit()

func start():
	if !afoot:
		PlayerManager.start()
		afoot = true

func end():
	if afoot:
		PlayerManager.end()
		afoot = false

func return_to_menu():
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")

func deploy_instance(what: Node2D, where: Vector2):
	if is_instance_valid(world):
		what.position = where
		world.add_child(what)

func deploy_ui_instance(what: Control, where: Vector2):
	if is_instance_valid(ui):
		what.position = where
		ui.add_child(what)

func print_multiplayer(what: String):
	print("Session %s: %s" % [multiplayer.get_unique_id(), what])
