extends Control


func _ready() -> void:
	Game.gameholder = self
	if Game.map:
		add_world(Game.map.instantiate())


func add_world(what: Node):
	%viewport.add_child(what)
