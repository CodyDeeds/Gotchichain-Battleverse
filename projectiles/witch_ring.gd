extends Projectile


## How fast the bullets spin on their axes
@export var bullet_spin_speed: float = -500
## The ring slows down, but how fast?
@export var friction: float = 0.4


func _ready() -> void:
	super()
	for this_hitbox in %hitboxes.get_children():
		if this_hitbox is Hitbox:
			this_hitbox.exceptions = exceptions

func _process(delta: float) -> void:
	super(delta)
	for this_hitbox in %hitboxes.get_children():
		if this_hitbox is Hitbox:
			this_hitbox.rotation += deg_to_rad( bullet_spin_speed * delta )
			
			if duration < 1 and randf()*40 < 1:
				this_hitbox.queue_free()
	
	velocity -= velocity * friction * delta

