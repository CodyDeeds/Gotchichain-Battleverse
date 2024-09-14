extends Projectile

## How fast the fireball falls
@export var projectile_gravity: float = 400
## How fast the fireball jumps after hitting the ground
@export var bounce_speed: float = 200

func _ready() -> void:
	super()
	
	acceleration = Vector2(0, projectile_gravity)

func _process(delta: float) -> void:
	super(delta)
	
	$downcast.target_position.y = 9 + velocity.y * delta
	
	if $downcast.is_colliding():
		velocity.y = min(velocity.y, -bounce_speed)
		# Play the sound when the fireball bounces
		#sound_player.play()
		
	if $rightcast.is_colliding() or $leftcast.is_colliding():
		# Play the sound when the fireball dies
		die()
