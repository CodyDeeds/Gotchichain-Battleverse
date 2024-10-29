extends Projectile


const fire_scene = preload("res://fx/fire_ground.tscn")


func deploy_fire():
	if %ground_finder.is_colliding():
		var fire_pos: Vector2 = %ground_finder.get_collision_point()
		var new_fire = Game.create_instance(fire_scene)
		Game.deploy_instance(new_fire, fire_pos)

func die():
	deploy_fire()
	super()
