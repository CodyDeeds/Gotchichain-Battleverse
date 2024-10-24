extends Projectile


func _ready() -> void:
	super()
	
	acceleration = Vector2(0, 500)
	velocity.y = randf_range(-1000, -400)
	var size: float = randf_range(.5, 1.5)
	scale = Vector2(size, size)
