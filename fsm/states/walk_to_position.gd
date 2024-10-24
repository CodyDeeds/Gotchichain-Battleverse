@tool
extends State


## X position that the entity will try to reach
@export var target_position: float = 0: set = set_target_position
## If it hasn't reached the position in this time, then it'll give up
@export var max_duration: float = 8

var starting_side: int = 0


func _step(delta: float):
	super(delta)
	
	father.accelerate(-starting_side, delta)
	var new_side = sign(father.global_position.x - target_position)
	if new_side != starting_side or starting_side == 0:
		enter_next_state()
	
	if age >= max_duration:
		enter_next_state()


func set_target_position(where: float):
	target_position = where
	starting_side = sign(father.global_position.x - target_position)
	if starting_side == 0:
		enter_next_state()
