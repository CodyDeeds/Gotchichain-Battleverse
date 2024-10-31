@tool
extends Node2D


## A texture with two frames: one unpressed and one pressed
@export var texture: Texture2D = null: set = set_texture
## The area that a player will have to enter in order to activate the button
@export var collision_shape: CollisionShape2D = null
## Whether the button can be pressed
@export var enabled: bool = true
## Whether the button automatically disables itself after being pressed
@export var auto_disable: bool = true
## After being pressed, the button will re-enable itself after this time. 0 = permanently disable
@export var auto_reenable_time: float = 0


signal activated


func _ready() -> void:
	if !Engine.is_editor_hint():
		collision_shape.reparent(%player_detector)


func enable():
	enabled = true
	$sprite.frame = 0

func disable():
	enabled = false
	$sprite.frame = 1

func activate():
	activated.emit()


func set_texture(what: Texture2D):
	texture = what
	%sprite.texture = what

func set_enabled(what: bool):
	if what:
		enable()
	else:
		disable()


func _on_player_detector_player_within() -> void:
	if enabled:
		activate()
		
		if auto_disable:
			disable()
		
		if auto_reenable_time > 0:
			var new_timer := get_tree().create_timer(auto_reenable_time)
			new_timer.timeout.connect(enable)
