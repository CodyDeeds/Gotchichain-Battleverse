@icon("res://pieces/hurtbox.png")
class_name Hurtbox
extends Area2D

@export var teams: Array[int] = [0]
@export var invuln_duration := 0.1

var invuln_time := 0.0
var overlapping_hitboxes: Array[Hitbox] = []
var father: Node = null

signal hit

func _ready() -> void:
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	
	set_collision_layer_value(6, true)
	set_collision_mask_value(5, true)
	
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	
	if !is_instance_valid(father):
		father = get_parent()

func _process(delta: float) -> void:
	invuln_time -= delta
	if invuln_time <= 0:
		if overlapping_hitboxes.size() > 0:
			for i in range(overlapping_hitboxes.size()):
				var this_hitbox: Hitbox = overlapping_hitboxes[i]
				if this_hitbox.active:
					get_hit_by(this_hitbox)
					break

func get_hit_by(what: Hitbox):
	#print("Hurtbox: Getting hit by ", what.name)
	hit.emit(what)
	what.hit.emit(self)
	what.hit_being(father)
	invuln_time = invuln_duration

func is_compatible_hitbox(what: Hitbox) -> bool:
	for i in what.teams:
		if teams.has(i):
			if !what.exceptions.has(self):
				return true
	return false

func _on_area_entered(what: Area2D):
	#print("Hurtbox: Area entered by ", what.get_parent().name)
	if what is Hitbox and !overlapping_hitboxes.has(what) and is_compatible_hitbox(what):
		overlapping_hitboxes.append(what)
		#print("Hurtbox: Added hitbox ", what.name)

func _on_area_exited(what: Area2D):
	#print("Hurtbox: Area exited by ", what.get_parent().name)
	if overlapping_hitboxes.has(what):
		overlapping_hitboxes.erase(what)
		#print("Hurtbox: Removed hitbox ", what.name)
