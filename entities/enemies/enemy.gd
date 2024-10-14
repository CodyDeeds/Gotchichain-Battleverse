class_name Enemy
extends Entity


@export var value: int = 500

const coin_scene = preload("res://props/coin.tscn")


func _ready() -> void:
	super()
	
	collision_layer = 64
	collision_mask = 5


func deploy_coin(this_value: int, size: float):
	var new_coin = Game.create_instance(coin_scene)
	new_coin.value = this_value
	var pos: Vector2 = global_position
	pos += Vector2(randf()*8, 0).rotated(randf() * 2*PI)
	Game.deploy_instance(new_coin, pos)
	new_coin.change_scale(size)

func die():
	super()
	
	while value >= 1000:
		deploy_coin(1000, 2.0)
		value -= 1000
	while value >= 100:
		deploy_coin(100, 1.5)
		value -= 100
	while value >= 10:
		deploy_coin(10, 1.0)
		value -= 10
	while value >= 1:
		deploy_coin(1, 0.5)
		value -= 1
