class_name PlayerStats
extends Resource

@export var controller := 0
# Using an array in case we want to have different traits on different lives, like different gotchis
@export var lives: Array = [0, 0, 0]
# Using an array here too in case we want different traits on different health, like some kind of bomb health that damages nearby enemies when lost
@export var health: Array = [0, 0, 0, 0, 0]
@export var name := "Player X"
@export var multiplayer_owner: int = 1

var object: Player = null


func serialise() -> Array:
	var object_path: NodePath = ^""
	if is_instance_valid(object):
		object_path = object.get_path()
	
	var output: Array = []
	
	var numbers: PackedInt32Array = PackedInt32Array()
	numbers.append(controller)
	numbers.append(multiplayer_owner)
	numbers.append(lives.size())
	for i in lives:
		numbers.append(i)
	for i in health:
		numbers.append(i)
	output.append(numbers)
	
	output.append(name)
	output.append(object_path)
	
	return output

static func deserialise(data: Array) -> PlayerStats:
	#Game.print_multiplayer("Unpacking %s" % [data])
	var output: PlayerStats = PlayerStats.new()
	
	var numbers: PackedInt32Array = data[0]
	output.name = data[1]
	var object_path: NodePath = data[2]
	
	output.controller = numbers[0]
	output.multiplayer_owner = numbers[1]
	var life_count: int = numbers[2]
	for i in range(life_count):
		output.lives.append(numbers[3 + i])
	for i in range(3 + life_count, numbers.size()):
		output.health.append(numbers[i])
	
	if object_path == ^"":
		output.object = null
	else:
		output.object = Game.get_node(object_path)
		if output.object == null:
			Game.print_multiplayer("ERROR: No object at %s" % object_path)
	
	return output
