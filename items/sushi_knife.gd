@tool
extends Item

@export var chop_sound: AudioStream = preload("res://knife.ogg")
var sound_player: AudioStreamPlayer = null

func _ready() -> void:
	# Initialize and configure the sound player
	sound_player = AudioStreamPlayer.new()
	add_child(sound_player)
	sound_player.stream = chop_sound
	sound_player.volume_db = -10  # Set the volume to a quieter level
	print("Sushi Knife: Sound player initialized with volume: ", sound_player.volume_db)

func get_activated():
	super()
	if holder:
		print("Sushi Knife: Activated by ", holder.name)
	else:
		print("Sushi Knife: Activated with no holder")
	
	var peers = MattohaSystem.Client.GetLobbyPlayersIds()
	for peer_id in peers:
		rpc_id(peer_id, "rpc_chop")

@rpc("any_peer", "call_local", "reliable")
func rpc_chop():
	if holder:
		print("Sushi Knife: Chopping by ", holder.name)
		if is_instance_valid(holder):
			print("Sushi Knife: Valid holder ", holder.name)
			
			# Add the holder to exceptions before playing the chop animation
			$hitbox.add_exception(holder.get_hurtbox())

			# Connect to the animation signals using Callable
			$animator.connect("animation_started", Callable(self, "_on_animation_started"))
			$animator.connect("animation_finished", Callable(self, "_on_animation_finished"))

			# Play the chop animation
			$animator.play("chop")
			# Play the chop sound
			sound_player.play()
		else:
			print("Sushi Knife: Invalid holder")
	else:
		print("Sushi Knife: No holder found")

func _on_animation_started(anim_name):
	if anim_name == "chop":
		print("Sushi Knife: Animation 'chop' started")

func _on_animation_finished(anim_name):
	if anim_name == "chop":
		print("Sushi Knife: Animation 'chop' finished")
		# Remove the holder from exceptions after the animation is done
		if holder:
			$hitbox.remove_exception(holder.get_hurtbox())
			print("Sushi Knife: Removed holder exception for ", holder.name)
		# Disconnect signals to avoid redundant calls
		$animator.disconnect("animation_started", Callable(self, "_on_animation_started"))
		$animator.disconnect("animation_finished", Callable(self, "_on_animation_finished"))

# Function to set the owner of the sushi knife
func set_knife_owner(new_owner):
	holder = new_owner
	print("Sushi Knife: Set owner to ", holder.name)

# Function handling collision with player
func _on_hitbox_area_entered(area):
	if area is Hurtbox:
		var player = area.get_parent()
		print("Sushi Knife: Collision with player ", player.name)
		if player != holder:  # Ensure the knife does not damage its owner
			print("Sushi Knife: Damaging player ", player.name)
			$hitbox.hit_being(player)
		else:
			print("Sushi Knife: Skipping damage to owner ", player.name)
