@tool
extends Item


var active: bool = false

const obj_space_laser = preload("res://projectiles/space_laser.tscn")


func explode():
	if multiplayer.get_unique_id() == get_multiplayer_authority():
		var new_laser = Game.create_instance(obj_space_laser)
		Game.deploy_instance(new_laser, global_position)
	queue_free()

@rpc("any_peer", "call_local")
func trigger_countdown():
	%activation_timer.start()
	%animator.play("activate")
	grabable = false
	active = false
	%glow.scale *= 1.5
	%glow.modulate.a *= 2

@rpc("any_peer", "call_local")
func activate():
	active = true
	%glow.show()
	%sfx_beep.activate()

func warn():
	%sfx_warning.activate()
	#%sfx_warning.minimum_pitch += 0.05

func get_activated():
	super()
	rpc("activate")

func get_thrown():
	super()
	rotation = 0


func _on_player_entered() -> void:
	if active and is_multiplayer_authority():
		rpc("trigger_countdown")
