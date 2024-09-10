@icon("res://pieces/hitbox.png")
class_name Hitbox
extends Area2D

@export var teams: Array[int] = [0]
@export var damage := 0.0
## Amount of time after hitting something, after which that same target can be hit again
@export var hit_interval: float = 0.0
@export var radial_knockback := 500.0
@export var directional_knockback := Vector2()
@export var active := true
@export var exceptions: Array[Hurtbox] = []

## Keys are hurtboxes, values are times in seconds
var temporary_exceptions: Dictionary = {}

signal hit

func _ready() -> void:
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	
	set_collision_layer_value(5, true)
	set_collision_mask_value(6, true)

func _process(delta: float) -> void:
	for this_hurtbox in temporary_exceptions:
		temporary_exceptions[this_hurtbox] -= delta
		if temporary_exceptions[this_hurtbox] <= 0:
			temporary_exceptions.erase(this_hurtbox)


func add_exception(what: Hurtbox):
	if !exceptions.has(what):
		exceptions.append(what)
		#print("Hitbox: Added exception ", what.name)

func remove_exception(what: Hurtbox):
	if exceptions.has(what):
		exceptions.erase(what)
		#print("Hitbox: Removed exception ", what.name)

func get_overlapping_hurtboxes():
	var output: Array[Hurtbox] = []
	for i in get_overlapping_areas():
		if i is Hurtbox:
			if i.is_compatible_hitbox(self) and !exceptions.has(i):
				output.append(i)
	return output

func hit_being(what):
	#print("Hitbox of %s: Hitting being %s" % [name, what.name])
	what.take_damage(damage)
	var direction = (what.global_position - global_position).normalized()
	var this_radial_knockback = radial_knockback * direction
	var this_directional_knockback = directional_knockback.rotated(global_rotation)
	what.take_knockback(this_radial_knockback + this_directional_knockback)
	hit.emit()
