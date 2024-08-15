extends Projectile

## How fast the fireball falls
@export var projectile_gravity: float = 400
## How fast the fireball jumps after hitting the ground
@export var bounce_speed: float = 200
## Sound effect for the fireball
@export var fireball_sound: AudioStream = preload("res://items/fireball.ogg")

func _ready() -> void:
	super()
	
	acceleration = Vector2(0, projectile_gravity)

	# Initialize and configure the sound player if it's not already set
	if sound_player == null:
		sound_player = AudioStreamPlayer.new()
		add_child(sound_player)
	sound_player.stream = fireball_sound
	sound_player.volume_db = -15  # Set the volume to a quieter level
	print("Fireball: Sound player initialized with volume: ", sound_player.volume_db)
	
	# Play the sound when the fireball is created
	sound_player.play()

func _process(delta: float) -> void:
	super(delta)
	
	$downcast.target_position.y = 9 + velocity.y * delta
	
	if $downcast.is_colliding():
		velocity.y = min(velocity.y, -bounce_speed)
		# Play the sound when the fireball bounces
		sound_player.play()
		
	if $rightcast.is_colliding() or $leftcast.is_colliding():
		# Play the sound when the fireball dies
		sound_player.play()
		die()
