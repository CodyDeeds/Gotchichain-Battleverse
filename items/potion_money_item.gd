@tool
extends Item


## Amount of money to release on smashing open the potion
@export var value: int = 150

const potion_scene = preload("res://projectiles/potion_money.tscn")


func get_activated():
	super()
	
	var new_potion = Game.create_instance(potion_scene)
	Game.deploy_instance(new_potion, global_position)
	
	new_potion.velocity = Vector2(500, -500)
	new_potion.velocity.x *= %flip.scale.y
	new_potion.value = value
	
	queue_free()
