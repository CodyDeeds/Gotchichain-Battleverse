@tool
extends Gun


func shoot():
	for i in range(randi_range(10, 18)):
		deploy_projectile(0, randf_range(.5, 1.5))
