@tool
extends Item

@export var explosion_sound: AudioStream = preload("res://audio/sfx/bomb.ogg")

var sound_player: AudioStreamPlayer = null
var sound_timer: Timer = null

func _ready() -> void:
	super()
	initialize_sound_player()

func initialize_sound_player():
	if sound_player == null:
		sound_player = AudioStreamPlayer.new()
		get_tree().root.add_child(sound_player)  # Add to the scene tree root, not as a child of grenade
		sound_player.stream = explosion_sound
		sound_player.volume_db = -15  # Set the volume to a quieter level
		#print("Grenade: Sound player initialized with volume: ", sound_player.volume_db)
	
	if sound_timer == null:
		sound_timer = Timer.new()
		get_tree().root.add_child(sound_timer)  # Add to the scene tree root, not as a child of grenade
		sound_timer.wait_time = 5.78
		sound_timer.one_shot = true
		if not sound_timer.is_connected("timeout", Callable(self, "_on_sound_finished")):
			sound_timer.connect("timeout", Callable(self, "_on_sound_finished"))

func get_activated():
	super()
	#print("Grenade: Activated")
	initialize_sound_player()
	var peers = MattohaSystem.Client.GetLobbyPlayersIds()
	for peer_id in peers:
		rpc_id(peer_id, "rpc_flash")
	play_sound()

@rpc("any_peer", "call_local", "reliable")
func rpc_flash():
	play_sound()
	$animator.play("flash")

func explode():
	var peers = MattohaSystem.Client.GetLobbyPlayersIds()
	for peer_id in peers:
		rpc_id(peer_id, "rpc_explode")

@rpc("any_peer", "call_local", "reliable")
func rpc_explode():
	%explosion_spawner.activate()
	#print("Grenade: Explosion triggered, waiting for sound to finish")
	queue_free()  # Ensure grenade is removed immediately after the explosion

func play_sound():
	if sound_player and sound_player.stream:
		sound_player.play()
		sound_timer.start()
		#print("Grenade: Playing sound: ", sound_player.stream)
	#else:
		#print("Grenade: Sound player or stream not initialized")

func _on_sound_finished():
	sound_player.queue_free()
	#print("Grenade: Queue free after sound finished playing")
