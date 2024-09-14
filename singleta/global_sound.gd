extends Node


var all_sfx: Dictionary = {}
# Key: String index, value: Array of AudioStreams
var multi_sfx: Dictionary = {}

const sfx_group = preload("res://audio/sfx/all_sfx.tres")


func _ready() -> void:
	log_all_sfx(sfx_group)


func log_all_sfx(what: ResourceGroup):
	var list = what.load_all()
	
	for this_sfx in list:
		var this_name = log_sfx(this_sfx)
		
		var ending_int: int = Util.get_ending_int(this_name)
		if ending_int >= 0:
			var this_index: StringName = this_name.trim_suffix( str(ending_int) )
			
			if !multi_sfx.has(this_index):
				multi_sfx[this_index] = []
			
			multi_sfx[this_index].append(this_sfx)

func log_sfx(what: AudioStream) -> String:
	var title = what.resource_path
	title = Util.get_filename(title)
	all_sfx[StringName(title)] = what
	return title

func get_sfx(what: StringName) -> AudioStream:
	if multi_sfx.has(what):
		return multi_sfx[what].pick_random()
	if all_sfx.has(what):
		return all_sfx[what]
	return null

func sfx_exists(what: StringName) -> bool:
	return all_sfx.has(what) or multi_sfx.has(what)

func create_sfx_controller(what: StringName) -> SFXController:
	var new_controller: SFXController = SFXController.new()
	new_controller.stream = get_sfx(what)
	return new_controller

func play_sfx(what: StringName) -> SFX:
	if sfx_exists(what):
		var new_sfx: SFX = SFX.new()
		get_tree().get_root().add_child(new_sfx)
		
		var controller: SFXController = create_sfx_controller( what )
		# Configure controller here
		new_sfx.add_child(controller)
		return new_sfx
	elif what != &"":
		push_warning("Attempting to play nonexistent SFX %s" % what)
	return null

func play_sfx_2d(what: StringName, where: Vector2) -> SFX2D:
	if sfx_exists(what):
		var new_sfx: SFX2D = SFX2D.new()
		Game.deploy_instance(new_sfx, where)
		
		var controller: SFXController = create_sfx_controller( what )
		# Configure controller here
		new_sfx.add_child(controller)
		return new_sfx
	elif what != &"":
		push_warning("Attempting to play nonexistent SFX %s" % what)
	return null
