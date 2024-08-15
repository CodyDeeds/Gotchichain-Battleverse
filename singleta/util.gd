extends Node


func get_nearest_group_member(group: String, pos: Vector2) -> Node2D:
	var output: Node2D = null
	
	var nearest_distance := 1000000000.0
	for i in get_tree().get_nodes_in_group(group):
		var this_distance = i.global_position.distance_squared_to(pos)
		if this_distance < nearest_distance:
			nearest_distance = this_distance
			output = i
	
	return output

func is_group_member_near(group: String, pos: Vector2, distance: float) -> bool:
	for i in get_tree().get_nodes_in_group(group):
		if i is Node2D and i.global_position.distance_squared_to(pos) < distance*distance:
			return true
	return false

func load_image(path: String) -> ImageTexture:
	var img = Image.new()
	var err = img.load(path)
	if err != OK:
		print("Error %s while loading image %s" % [err, path])
		breakpoint
	
	var tex = ImageTexture.create_from_image(img)
	
	return tex

func string_to_vec2(what: String) -> Vector2:
	what = what.replace("(", "")
	what = what.replace(")", "")
	var axes := what.split_floats(",")
	if axes.size() == 2:
		return Vector2(axes[0], axes[1])
	else:
		return Vector2()

func string_to_array(what: String) -> PackedStringArray:
	what = what.strip_edges()
	
	if what.begins_with("[") and what.ends_with("]"):
		what = what.substr(1, what.length() - 2)
		var output := what.split(",")
		for i in range(output.size()):
			output[i] = output[i].strip_edges()
			
			if output[i].begins_with('"') and output[i].ends_with('"'):
				output[i] = output[i].substr(1, output[i].length() - 2)
			
			if output[i].begins_with("'") and output[i].ends_with("'"):
				output[i] = output[i].substr(1, output[i].length() - 2)
		return output
	else:
		return PackedStringArray([what])

func get_filename(what: String) -> String:
	var output := what.get_basename()
	var slash = output.find("/")
	while slash >= 0:
		output = output.substr(slash+1)
		slash = output.find("/")
	return output

func get_all_descendents(what: Node) -> Array:
	var output: Array = [what]
	
	for i in what.get_children():
		output.append_array( get_all_descendents(i) )
	
	return output

func map_range(value: float, from_min: float, from_max: float, to_min: float, to_max: float, limit: bool = false) -> float:
	var progress := value - from_min
	var ratio := progress / (from_max - from_min)
	if limit:
		ratio = clamp(ratio, 0, 1)
	return lerp(to_min, to_max, ratio)

func split_function(what: String) -> Dictionary:
	var output := {"object": "", "function": "", "args": []}
	
	var dot := -1
	var openbrackets := -1
	var closebrackets := -1
	var part := 0
	
	for i in range(what.length()):
		var character: String = what.substr(i, 1)
		match part:
			0:
				if character == ".":
					dot = i
					part = 1
				if character == "(":
					openbrackets = i
					part = 2
			1:
				if character == "(":
					openbrackets = i
					part = 2
			2:
				if character == ")":
					closebrackets = i
					break
	
	if dot >= 0:
		output["object"] = what.substr(0, dot).strip_edges()
	if openbrackets >= 0:
		output["function"] = what.substr(dot+1, openbrackets-dot-1).strip_edges()
	else:
		output["function"] = what.substr(dot+1).strip_edges()
	
	if openbrackets >= 0 and closebrackets >= 0:
		var arg_string = what.substr(openbrackets+1, closebrackets-openbrackets-1)
		var arg_array = []
		for this_arg in arg_string.split(","):
			arg_array.append(this_arg.strip_edges())
		output["args"] = arg_array
	
	return output

func is_web_build():
	return OS.get_name() == "Web"

func min_index(what: Array):
	var minimum := 1000000000.0
	var best_index: int = -1
	for i in range(what.size()):
		if what[i] < minimum:
			best_index = i
			minimum = what[i]
	return best_index

func max_index(what: Array):
	var maximum := -1000000000.0
	var best_index: int = -1
	for i in range(what.size()):
		if what[i] > maximum:
			best_index = i
			maximum = what[i]
	return best_index

func is_event_click(event: InputEvent, button: int = MOUSE_BUTTON_LEFT, press: bool = true):
	return event is InputEventMouseButton and event.button_index == button and event.pressed == press

func get_random_array_entry(array: Array) -> Variant:
	var index := randi() % array.size()
	return array[index]

func get_random_child(parent: Node) -> Node:
	var children = parent.get_children()
	var child_count := children.size()
	if child_count == 0:
		return null
	else:
		var index := randi() % child_count
		return children[index]
