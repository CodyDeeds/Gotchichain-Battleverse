@tool
extends Node2D


@export var props: Array[PackedScene] = []: set = set_props
@export var line: Vector2 = Vector2(): set = set_line
@export var interval: float = 32: set = set_interval
@export var randomness: float = 0.25: set = set_randomness


func _ready() -> void:
	deploy()


func clear():
	var kids = get_children()
	
	for i in kids:
		remove_child(i)
		i.queue_free()

func deploy():
	clear()
	
	if line == Vector2():
		return
	if props.size() <= 0:
		return
	
	var i: float = generate_interval(.5)
	var direction: Vector2 = line.normalized()
	var length: float = line.length()
	
	while i <= length:
		var this_prop = props.pick_random()
		if this_prop:
			var new_prop = this_prop.instantiate()
			add_child(new_prop)
			new_prop.position = i * direction
		
		var this_interval: float = generate_interval()
		i += this_interval


func generate_interval(multiplier: float = 1) -> float:
	return interval * randf_range( 1 - randomness, 1 + randomness ) * multiplier

func set_props(what: Array[PackedScene]):
	props = what
	deploy()

func set_line(what: Vector2):
	line = what
	deploy()

func set_interval(what: float):
	interval = what
	deploy()

func set_randomness(what: float):
	what = clamp(what, 0, 1)
	randomness = what
	deploy()
