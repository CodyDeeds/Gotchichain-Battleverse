@tool
extends Item

@export var explosion_sound: StringName = &""
@export var beep_sound: StringName = &""

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
	var peers = MattohaSystem.Client.GetLobbyPlayersIds()
	for peer_id in peers:
		rpc_id(peer_id, "rpc_explode")

@rpc("any_peer", "call_local", "reliable")
func rpc_explode():
	%explosion_spawner.activate()
	GlobalSound.play_sfx_2d(explosion_sound, global_position)
	#print("Grenade: Explosion triggered, waiting for sound to finish")
	queue_free()  # Ensure grenade is removed immediately after the explosion

