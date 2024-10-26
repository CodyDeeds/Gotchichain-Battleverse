extends Node2D


@export var value_weight: float = 0.05
var value: int = 0


func _init() -> void:
	add_to_group(&"value_sources")


func deploy_coins():
	Game.distribute_value()
	Game.deploy_coin_payload(value, global_position)


func _on_hurtbox_hit(_hitbox) -> void:
	deploy_coins()
	queue_free()
