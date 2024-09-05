@tool
extends State

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
			father.attempt_jump.rpc_id(1)
			father.rpc_set_floating.bind(true).rpc_id(1)
		if event.is_action_released("jump"):
			father.rpc_set_floating.bind(false).rpc_id(1)
		
		if event.is_action_pressed("grab"):
			father.attempt_grab.rpc_id(1)
		
		if event.is_action_pressed("use"):
			father.activate_item.rpc_id(1)

func tractutate():
	var traction: float = 0
	
	traction = Input.get_action_strength("move_right", father.controller) - Input.get_action_strength("move_left", father.controller)
	
	father.rpc_tractutate.bind(traction).rpc_id(1)
