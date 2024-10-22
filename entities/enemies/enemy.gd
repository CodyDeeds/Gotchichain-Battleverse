class_name Enemy
extends Entity


## The share of total value awarded by killing this enemy
## e.g. if every enemy has a weight of 1, the value is split equally
## but if one enemy has a weight of 2, it gets double as much as any other enemy
@export var value_weight: float = 1
@export var value: int = 0
@export var flying: bool = false

var last_grounded_position: Vector2 = Vector2()

const coin_scene = preload("res://props/coin.tscn")


func _init():
	super()
	add_to_group(&"enemies")
	# The value_sources group is specifically for things that derive value from player bets like enemies
	# They must exist from the very start of the game or the distribution may be inaccurate
	# Each must have a `value` and `value_weight` variable; int and float respectively
	add_to_group(&"value_sources")

func _ready() -> void:
	super()
	
	collision_layer = 64
	collision_mask = 5
	last_grounded_position = global_position

func _process(delta: float) -> void:
	super(delta)
	
	if is_on_floor():
		last_grounded_position = global_position


func die():
	super()
	
	Game.distribute_value()
	Game.deploy_coin_payload(value, global_position if flying else last_grounded_position)
