extends Node2D


@export var flipped: bool = false


func _on_spawn_timer_timeout() -> void:
	var new_frog = %spawner.activate()
	new_frog.set_flip(flipped)
	%animator.play(&"erupt")
