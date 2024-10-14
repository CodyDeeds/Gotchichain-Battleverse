@tool
extends State


@export var leap_velocity: Vector2 = Vector2(300, -300)

var flipped: bool = false


func _enter():
	super()
	
	father.velocity = leap_velocity
	if flipped:
		father.velocity.x *= -1

func _step(delta: float):
	super(delta)
	
	if age > 0.1 and father.is_on_floor():
		enter_next_state()

func _exit():
	super()
	
	father.velocity = Vector2()
