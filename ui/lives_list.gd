extends HBoxContainer
class_name LivesList

@export var life_icon: PackedScene
@export var player: int = 0

func update_lives(lives: Array):
	clear_lives()
	add_lives(lives)

func clear_lives():
	for i in get_children():
		i.queue_free()

func add_lives(lives: Array):
	for i in lives.size():
		var new_icon = life_icon.instantiate()
		add_child(new_icon)