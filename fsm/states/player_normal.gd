@tool
extends State


# This data probably doesn't belong in the player_normal state. consider movint it elsewhere
var left_pressed: bool = false
var right_pressed: bool = false


func _enter():
	super()
	
	for i in Input.get_connected_joypads():
		if i == father.controller and father.is_owner():
			var laterality: float = Input.get_joy_axis(i, JOY_AXIS_LEFT_X)
			if abs(laterality) > InputMap.action_get_deadzone(&"move_left"):
				if laterality < 0:
					left_pressed = true
				if laterality > 0:
					right_pressed = true
			else:
				left_pressed = Input.is_action_pressed("move_left")
				right_pressed = Input.is_action_pressed("move_right")

func _step(delta: float):
	super(delta)
	
	if (Game.is_multiplayer and !father.is_owner()):
		return
	
	tractutate()

func _handle_input(event: InputEvent):
	if (Game.is_multiplayer and !father.is_owner()):
		return
	
	# Ensure that inputs are processed only if they match the player's controller
	if event.device == father.controller:
		if event.is_action_pressed("jump"):
			#Game.print_multiplayer("Player jumps")
			if Input.is_action_pressed("move_down"):
				Game.call_server( father.attempt_drop )
			else:
				Game.call_server( father.attempt_jump )
			Game.call_server( father.rpc_set_floating.bind(true) )
		if event.is_action_released("jump"):
			Game.call_server( father.rpc_set_floating.bind(false) )
		
		if event.is_action_pressed("grab"):
			Game.call_server( father.attempt_grab )
		
		if event.is_action_pressed("use"):
			Game.call_server( father.activate_item )
		
		if event.is_action_pressed("move_left"):
			left_pressed = true
		if event.is_action_released("move_left"):
			left_pressed = false
		
		if event.is_action_pressed("move_right"):
			right_pressed = true
		if event.is_action_released("move_right"):
			right_pressed = false

func tractutate():
	var traction: float = 0
	
	if left_pressed:
		traction -= 1
	if right_pressed:
		traction += 1
	traction += Input.get_joy_axis(father.controller, JOY_AXIS_LEFT_X)
	traction = clamp(traction, -1, 1)
	
	Game.call_server( father.rpc_tractutate.bind(traction) )
