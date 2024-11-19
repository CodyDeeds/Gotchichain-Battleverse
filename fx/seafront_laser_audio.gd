extends Node


@export var charge_time := 1.0
@export var duration := 4.0

var loop_sfx: SFX = null


func _ready() -> void:
	GlobalSound.play_sfx(&"seafront_laser_start")
	get_tree().create_timer(charge_time).timeout.connect(func():
		loop_sfx = GlobalSound.play_sfx(&"seafront_laser_loop")
	)
	get_tree().create_timer(charge_time + duration).timeout.connect(end)


func end():
	GlobalSound.play_sfx(&"seafront_laser_end")
	loop_sfx.stop()
	loop_sfx.queue_free()
	queue_free()
