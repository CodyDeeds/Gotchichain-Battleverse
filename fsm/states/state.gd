@tool
class_name State
extends Node


@export var animation := ""
@export var next_state := ""
@export var auto_proceed := true

var active: bool = false
var age := 0.0
var father: Node = null
var parent: Node = null
var fsm: FSM = null


signal entered
signal exited


func _ready():
	parent = get_parent()
	fsm = parent
	if !fsm:
		push_warning("State %s is not a child of Finite State Machine" % name)
	
	tree_entered.connect(_on_tree_updated)

func _process(delta):
	if active:
		_step(delta)

func _input(event: InputEvent) -> void:
	if active:
		_handle_input(event)

func _get_configuration_warnings():
	var this_parent = get_parent()
	if this_parent is FSM:
		return []
	else:
		return ["Parent must be a Finite State Machine"]


func _enter():
	active = true
	entered.emit()

func _exit():
	active = false
	age = 0
	exited.emit()

func _step(delta: float):
	age += delta

func _handle_input(_event: InputEvent):
	pass


func enter_next_state():
	set_state(next_state)

func set_state(what: String):
	if active:
		fsm.set_state(what)


func _on_tree_updated():
	if Engine.is_editor_hint():
		if is_instance_valid(parent): parent.script_changed.disconnect(update_configuration_warnings)
		parent = get_parent()
		parent.script_changed.connect(update_configuration_warnings)
		
		update_configuration_warnings()

func _on_animation_finished():
	if auto_proceed and next_state != "":
		enter_next_state()
