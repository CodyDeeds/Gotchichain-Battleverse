## A type of Projectile that flies out from its thrower before coming back
class_name Boomerang
extends Projectile


@export_group("Movement")
## Speed of this boomerang as it flies away from the thrower
@export var fly_speed: float = 300.0
## Duration under which this boomerang will move forward
## If set to zero, can travel forever
@export var fly_time: float = 2.0
## Duration over which this boomerang will slow to a halt
@export var brake_time: float = 1.0
## Distance this boomerang can travel from its thrower
## If set to zero, can travel any distance
## If zero and [code]fly_time[/code] is also zero, this boomerang will immediately linger
@export var fly_distance: float = 0.0
## Duration with which this boomerang stays still at the apex of its arc
@export var linger_duration: float = 1.0
## Duration over which this boomerang reaches max speed when returning to thrower
@export var acceleration_time: float = 1.0
## Speed with which this boomerang returns to its thrower
@export var return_speed: float = 500.0
## Boomerang must be within this distance of thrower in order to be collected
@export var collection_distance: float = 32.0


enum STATE {
	FLY,
	LINGER,
	RETURN
}

var state: STATE = STATE.FLY
var state_age: float = 0.0
var father: Node2D = null

signal collected


func _process(delta: float) -> void:
	super(delta)
	state_age += delta
	
	match state:
		STATE.FLY:
			if fly_time > 0:
				var speed_factor: float
				if brake_time > 0:
					speed_factor = clamp((fly_time - state_age) / brake_time, 0, 1)
				else:
					speed_factor = 1
				
				velocity = velocity.normalized() * speed_factor * fly_speed
				if state_age >= fly_time:
					enter_state(STATE.LINGER)
			
			if fly_distance > 0:
				var distance_squared: float = father.global_position.distance_squared_to(global_position)
				if distance_squared > fly_distance*fly_distance:
					enter_state(STATE.LINGER)
			
			if fly_time <= 0 and fly_distance <= 0:
				enter_state(STATE.LINGER)
		STATE.LINGER:
			velocity = Vector2()
			linger_duration -= delta
			if linger_duration <= 0:
				enter_state(STATE.RETURN)
		STATE.RETURN:
			if is_instance_valid(father):
				var distance_squared: float = father.global_position.distance_squared_to(global_position)
				if distance_squared <= collection_distance*collection_distance:
					get_collected()
				
				var dir: Vector2 = (father.global_position - global_position).normalized()
				var speed_factor: float
				if acceleration_time > 0:
					speed_factor = clamp(state_age / acceleration_time, 0, 1)
				else:
					speed_factor = 1
				velocity = dir * speed_factor * return_speed
			else:
				die()


func enter_state(what: STATE):
	state = what
	state_age = 0

func get_collected():
	collected.emit()
	die()
