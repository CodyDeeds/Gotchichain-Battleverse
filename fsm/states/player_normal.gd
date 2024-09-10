@tool
extends State


# This data probably doesn't belong in the player_normal state. consider movint it elsewhere
var left_pressed: bool = false
var right_pressed: bool = false


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
