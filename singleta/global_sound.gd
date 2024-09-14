extends Node


var all_sfx: Dictionary = {}


func _ready() -> void:
	var list = load("res://audio/sfx/all_sfx.tres").load_all()
	for this_sfx in list:
		log_sfx(this_sfx)


func log_sfx(what: AudioStream):
	var title = what.resource_path
	title = Util.get_filename(title)
	all_sfx[StringName(title)] = what

## Assumes that the relevant SFX actually exists
func create_sfx_controller(what: StringName) -> SFXController:
	var new_controller: SFXController = SFXController.new()
	new_controller.stream = all_sfx[what]
	return new_controller

func play_sfx(what: StringName):
	if all_sfx.has(what):
		var new_sfx: SFX = SFX.new()
		get_tree().get_root().add_child(new_sfx)
		
		var controller: SFXController = create_sfx_controller( what )
		# Configure controller here
		new_sfx.add_child(controller)
	elif what != &"":
		push_warning("Attempting to play nonexistent SFX %s" % what)

func play_sfx_2d(what: StringName, where: Vector2):
	if all_sfx.has(what):
		var new_sfx: SFX2D = SFX2D.new()
		Game.deploy_instance(new_sfx, where)
		
		var controller: SFXController = create_sfx_controller( what )
		# Configure controller here
		new_sfx.add_child(controller)
	elif what != &"":
		push_warning("Attempting to play nonexistent SFX %s" % what)
