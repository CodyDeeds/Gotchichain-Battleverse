@tool
class_name RotatorToMotion
extends Node


@export var active: bool = true
## How fast this lerps the rotation to the desired angle. Negative values snap instantly
@export var speed: float = -1
## Parent must be moving at least this fast for rotation to occur
@export var speed_requirement: float = 10
## How much extra rotation to add (degrees)
@export var extra_rotation: float = 0

var prev_position: Vector2


func _ready() -> void:
	tree_entered.connect(_on_tree_updated)

func _process(delta: float) -> void:
	if active:
		rotate_parent(delta)
	
	if get_parent() is Node2D:
		prev_position = get_parent().global_position

func _get_configuration_warnings():
	if get_parent() is Node2D:
		return PackedStringArray()
	else:
		return PackedStringArray(["Rotator To Motion must be a child of a Node2D"])


func rotate_parent(delta: float):
	var father: Node2D = get_parent() as Node2D
	if father:
		var motion: Vector2 = father.global_position - prev_position
		var target_speed: float = speed_requirement * delta
		if motion.length_squared() >= target_speed*target_speed:
			var dir: float = prev_position.angle_to_point(father.global_position)
			dir += deg_to_rad(extra_rotation)
			if speed >= 0:
				father.rotation = lerp_angle(father.rotation, dir, speed*delta)
			else:
				father.rotation = dir


func _on_tree_updated():
	update_configuration_warnings()
