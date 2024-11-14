extends Node2D


@export var damage := 3
@export var bomb_speed := 3000.0
@export var duration := 2.0

var source_direction := Vector2(0, -1)

const explosion_scene = preload("res://projectiles/explosion.tscn")


func _ready() -> void:
	snap_to_ground()
	randomise_direction()
	%groundfinder.enabled = false

func _process(delta: float) -> void:
	duration -= delta
	reposition_bomb()
	if duration <= 0:
		explode()


func get_max_floor_distance() -> float:
	return %groundfinder.target_position.y

func randomise_direction():
	source_direction = Vector2(0, -1).rotated( randf_range(-.5, .5) )

func reposition_bomb():
	%bomb.position = source_direction * duration * bomb_speed
	%bomb.rotation = (-source_direction).angle()

func snap_to_ground():
	%groundfinder.hit_from_inside = true
	%groundfinder.force_raycast_update()
	
	if delete_if_in_wall():
		return
	
	if %groundfinder.is_colliding():
		global_position = %groundfinder.get_collision_point()
	else:
		queue_free()

func delete_if_in_wall() -> bool:
	if %groundfinder.is_colliding():
		var hit_pos: Vector2 = %groundfinder.get_collision_point()
		if hit_pos.distance_squared_to( %groundfinder.global_position ) < 16:
			queue_free()
			return true
	
	return false

func explode():
	deploy_explosion()
	reparent_smoke()
	queue_free()

func deploy_explosion():
	var new_explosion = explosion_scene.instantiate()
	new_explosion.damage = damage
	Game.deploy_instance(new_explosion, global_position)

func reparent_smoke():
	if is_instance_valid(Game.world):
		var smoke: CPUParticles2D = %smoke as CPUParticles2D
		smoke.reparent(Game.world)
		smoke.emitting = false
		get_tree().create_timer( smoke.lifetime ).timeout.connect( smoke.queue_free )
