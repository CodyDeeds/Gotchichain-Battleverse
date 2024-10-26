extends Node2D


@export var solid = true
@export var value_weight: float = 0.05
var value: int = 0

const particle_scene = preload("res://fx/crate_break.tscn")


func _init() -> void:
	add_to_group(&"value_sources")

func _ready() -> void:
	%collision_shape.disabled = !solid


func deploy_coins():
	Game.distribute_value()
	Game.deploy_coin_payload(value, global_position)


func _on_hurtbox_hit(_hitbox) -> void:
	deploy_coins()
	var new_particles = particle_scene.instantiate()
	Game.deploy_instance(new_particles, global_position)
	queue_free()
