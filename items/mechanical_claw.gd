@tool
extends Gun


## It's possible that whomever we grab gets stuck on something. After this amount of time we'll give up and let them go
@export var max_grab_time: float = 12
## Acceleration imparted upon the target toward the hooker
@export var pull_acceleration: float = 8000
## Aim to pull the target at this speed
@export var pull_speed: float = 1000
## Aim to pull the target to within this distance
@export var pull_target_distance: float = 64

var grabbed_entity: Entity = null
var current_grab_time: float = max_grab_time
var current_claw: Projectile = null


func _process(delta: float) -> void:
	super(delta)
	
	if is_instance_valid(grabbed_entity):
		pull_target(delta)
		
		current_grab_time -= delta
		if current_grab_time <= 0:
			release_entity()
			
		if is_instance_valid(grabbed_entity):
			var relative: Vector2 = grabbed_entity.global_position - global_position
			if is_instance_valid(holder):
				relative = grabbed_entity.global_position - holder.global_position
			if relative.length_squared() < pull_target_distance*pull_target_distance:
				release_entity()
	elif shoot_veto:
		grabbed_entity = null
		shoot_veto = false
		%sprite.frame = 1
	
	reposition_chain()


func pull_target(delta: float):
	var relative: Vector2 = grabbed_entity.global_position - global_position
	var dir: Vector2 = relative.normalized()
	grabbed_entity.velocity -= dir * pull_acceleration * delta

func reposition_chain():
	if is_instance_valid(grabbed_entity):
		%chain.show()
		
		var relative: Vector2 = grabbed_entity.global_position - global_position
		%chain.global_position = (global_position + grabbed_entity.global_position) / 2
		%chain.global_rotation = relative.angle()
		%chain.region_rect.size.x = relative.length()
	else:
		%chain.hide()

func shoot():
	super()
	shoot_veto = true
	%sprite.frame = 1

func deploy_projectile(angle: float=0.0, speed_mult: float=1.0):
	var new_shot = super(angle, speed_mult)
	new_shot.father = self
	current_claw = new_shot
	
	current_claw.expired.connect(_on_shot_slain)
	current_claw.crashed.connect(_on_shot_slain)

func grab_entity(what: Entity):
	grabbed_entity = what
	current_grab_time = max_grab_time

func release_entity():
	grabbed_entity = null
	shoot_veto = false
	%sprite.frame = 0


func _on_shot_slain():
	current_claw.expired.disconnect(_on_shot_slain)
	current_claw.crashed.disconnect(_on_shot_slain)
	current_claw = null
	shoot_veto = false
	%sprite.frame = 0
