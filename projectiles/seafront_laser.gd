extends Node2D


@export var duration: float = 4



func queue_depart():
	var new_timer := get_tree().create_timer(duration)
	new_timer.timeout.connect(depart)

func depart():
	var particulation = %particulation
	particulation.reparent(Game.world)
	particulation.activate()
	queue_free()
