class_name FSM
extends Node


@export var search_deep_for_animator := true
## Whether or not to print state changes for debug purposes
@export var print_state_changes := false

var current_state: State = null
var state_name := ""
var states := {}
var father: Node = null
var animator: AnimationPlayer = null


func _ready():
	set_father()
	set_state_instance(get_child(0))


func catalogue_states():
	for i in get_children():
		var this_state = i as State
		if this_state:
			states[this_state.name] = this_state
			this_state.father = father

func set_father(what: Node = null, override: bool = false):
	if !is_instance_valid(father) or override:
		if !is_instance_valid(what):
			father = get_parent()
		else:
			father = what
		
		animator = get_animator()
		connect_animator()
		catalogue_states()

func get_animator() -> AnimationPlayer:
	var targets = Util.get_all_descendents(father) if search_deep_for_animator else father.get_children()
	
	for i in targets:
		if i is AnimationPlayer:
			return i
	
	return null

func connect_animator():
	if is_instance_valid(animator):
		var connections = animator.animation_finished.get_connections()
		var already_connected := false
		for i in connections:
			if i["callable"] == _on_animation_finished:
				already_connected = true
				break
		
		if !already_connected:
			animator.animation_finished.connect(_on_animation_finished)

func play_animation(what: String):
	if is_instance_valid(animator):
		if animator.has_animation(what):
			animator.play(what)
		else:
			push_warning("FSM attempts to play animation %s, but it does not exist" % what)

func set_state(what: String):
	if states.has(what):
		set_state_instance(states[what])
	else:
		push_warning("Trying to change to state %s, which does not exist" % what)

func set_state_instance(what: State):
	if is_instance_valid(current_state):
		current_state._exit()
	
	current_state = what
	state_name = what.name
	if print_state_changes:
		var _state_name = "null"
		if is_instance_valid(what):
			_state_name = what.name
		print("%s: Changing state to %s" % [father.name, _state_name])
	
	if current_state.animation != "":
		play_animation(current_state.animation)
	
	if is_instance_valid(current_state):
		current_state._enter()


func _on_animation_finished(_animname: String):
	current_state._on_animation_finished()
