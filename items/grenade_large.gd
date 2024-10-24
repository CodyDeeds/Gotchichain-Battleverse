@tool
extends Item

@export var explosion_sound: StringName = &""
@export var beep_sound: StringName = &""
## Number of explosions
@export var explosion_count: int = 8
## Delay between one explosion and the next
@export var explosion_delay: float = 0.1
## Maximum distance from the grenade that explosions can spawn
@export var explosion_reach: float = 48

const multi_explosion_scene = preload("res://projectiles/explosion_multi.tscn")


func _ready() -> void:
	super()


func get_activated():
	super()
	var peers = MattohaSystem.Client.GetLobbyPlayersIds()
	for peer_id in peers:
		rpc_start_timer.rpc_id(peer_id)

@rpc("any_peer", "call_local", "reliable")
func rpc_start_timer():
	$animator.play("flash")

func flash():
	%sprite.frame = 1
	var timer := get_tree().create_timer(.1)
	timer.timeout.connect(func():
		%sprite.frame = 0
	)
	GlobalSound.play_sfx_2d("beep", global_position)

func explode():
	var new_multi_explosion = Game.create_instance(multi_explosion_scene)
	new_multi_explosion.explosion_reach = 96
	Game.deploy_instance(new_multi_explosion, global_position)
	queue_free()

