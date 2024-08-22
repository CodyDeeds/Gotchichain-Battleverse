@tool
extends Item

@export var chop_sound: AudioStream = preload("res://knife.ogg")
var sound_player: AudioStreamPlayer = null

func _ready() -> void:
	# Initialize and configure the sound player
	sound_player = AudioStreamPlayer.new()
	add_child(sound_player)
	sound_player.stream = chop_sound
	sound_player.volume_db = -15  # Set the volume to a quieter level

func get_activated():
	super()
	chop()

func chop():
	if holder:
		if is_instance_valid(holder):
			# Add the holder to exceptions before playing the chop animation
			$hitbox.add_exception(holder.get_hurtbox())

			# Connect to the animation signals using Callable
			$animator.animation_finished.connect(_on_animation_finished)

			# Play the chop animation
			$animator.play("chop")
			# Play the chop sound
			sound_player.play()

func _on_animation_finished(anim_name):
	if anim_name == "chop":
		# Remove the holder from exceptions after the animation is done
		if holder:
			$hitbox.remove_exception(holder.get_hurtbox())
		# Disconnect signals to avoid redundant calls
		$animator.animation_finished.disconnect(_on_animation_finished)

# Function to set the owner of the sushi knife
func set_knife_owner(new_owner):
	holder = new_owner
	#print("Sushi Knife: Set owner to ", holder.name)

# Function handling collision with player
func _on_hitbox_area_entered(area):
	if area is Hurtbox:
		var player = area.get_parent()
		#print("Sushi Knife: Collision with player ", player.name)
		if player != holder:  # Ensure the knife does not damage its owner
			#print("Sushi Knife: Damaging player ", player.name)
			$hitbox.hit_being(player)
		#else:
			#print("Sushi Knife: Skipping damage to owner ", player.name)
