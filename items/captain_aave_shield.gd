@tool
extends Gun


func deploy_projectile(angle: float = 0.0, speed_mult: float = 1.0):
	var new_projectile = super(angle, speed_mult)
	new_projectile.father = holder
	
	if is_instance_valid(holder):
		new_projectile.collected.connect(holder.spawn_item.bind(scene_file_path))
	queue_free()


func _on_projectile_collected():
	reload()
	%sprite.show()
