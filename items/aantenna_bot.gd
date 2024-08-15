@tool
extends Item


var active: bool = false

const obj_space_laser = preload("res://projectiles/space_laser.tscn")


func explode():
	var new_laser = MattohaSystem.CreateInstance(obj_space_laser.resource_path)
	MattohaSystem.GetLobbyNodeFor(self).add_child(new_laser)
	new_laser.global_position = global_position
	queue_free()

func get_activated():
	super()
	active = true
	%glow.show()

func get_thrown():
	super()
	rotation = 0


func _on_player_entered() -> void:
	if active:
		%activation_timer.start()
		%animator.play("activate")
		grabable = false
		active = false
