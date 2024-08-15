extends Node2D


func _ready():
	Game.world = self
	Game.start()
