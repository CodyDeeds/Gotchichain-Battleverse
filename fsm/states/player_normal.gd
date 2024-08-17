@tool
extends State

func _step(delta: float):
	super(delta)
	tractutate(delta)

func _handle_input(event: InputEvent):
	if (!MattohaSystem.IsNodeOwner(self)):
		return
	
	if event.device == father.controller:
		if event.is_action_pressed("jump"):
			father.jump()

		if event.is_action_pressed("grab"):
			father.attempt_grab()

		if event.is_action_pressed("use"):
			father.activate_item()

func tractutate(delta: float):
	var traction: float = 0
	
	traction = Input.get_joy_axis(father.controller, JOY_AXIS_LEFT_X)
	
	father.accelerate(traction, delta)
