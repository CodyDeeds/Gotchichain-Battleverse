extends Node2D


## Frogs spawn facing left if flipped; facing right if not
@export var flipped: bool = false


func _ready() -> void:
	var original_time: float = %spawn_timer.wait_time
	var new_time: float = original_time - randf() * 2
	%spawn_timer.stop()
	%spawn_timer.start(new_time)
	%spawn_timer.wait_time = original_time


func _on_spawn_timer_timeout() -> void:
	var new_frog = %spawner.activate()
	new_frog.set_flip(flipped)
	%animator.play(&"erupt")
