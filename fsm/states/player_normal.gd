@tool
extends State

func _step(delta: float):
	super(delta)
	tractutate(delta)

func _handle_input(event: InputEvent):
	if (Game.is_multiplayer and !father.is_owner()):
		return
	
	# Ensure that inputs are processed only if they match the player's controller
	if event.device == father.controller:
		if event.is_action_pressed("jump"):
			father.attempt_jump.rpc_id(1)

		if event.is_action_pressed("grab"):
			father.attempt_grab.rpc_id(1)

		if event.is_action_pressed("use"):
			father.activate_item()

func tractutate(delta: float):
	var traction: float = 0
	
	traction = Input.get_joy_axis(father.controller, JOY_AXIS_LEFT_X)
	
	father.accelerate(traction, delta)
