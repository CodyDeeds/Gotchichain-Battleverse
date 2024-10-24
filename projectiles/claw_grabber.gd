extends Projectile


var father: Gun = null


func hit_being(what):
	if what is Entity and is_instance_valid(father):
		father.grab_entity(what)
		queue_free()
