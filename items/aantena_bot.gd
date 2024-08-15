@tool
extends Item


var active: bool = false

const obj_space_laser = preload("res://projectiles/space_laser.tscn")


func explode():
	var new_laser = obj_space_laser.instantiate()
	Game.deploy_instance(new_laser, global_position)
	queue_free()

func get_activated():
	super()
	active = true
	%glow.show()


func _on_player_entered() -> void:
	if active:
		%activation_timer.start()
		%animator.play("activate")
