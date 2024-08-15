extends Gun


func _process(delta: float) -> void:
	super(delta)

func shoot():
	deploy_projectile()
	deploy_projectile( 10, .5)
	deploy_projectile(-10, .5)
