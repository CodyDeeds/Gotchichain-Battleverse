@icon("res://items/gun.png")
class_name Gun
extends Item

## Bullets are spawned at the location of this node
@export var barrel: Node2D = null
@export_group("Stats")
@export var projectile_speed := 2000.0
@export var projectile_spread := 5.0
@export var can_hit_shooter := false
## "Rate of Fire interval": Time between one allowed shot and the next, in seconds
@export var rof_interval := 0.25
@export var gun_kickback := 20.0
@export var player_kickback := 0.0
@export_group("Resources")
@export var projectile: PackedScene = null
@export var shoot_particle_scene: PackedScene = null

var timer_rof := Timer.new()
var can_shoot := true

func _ready() -> void:
	add_child(timer_rof)
	timer_rof.wait_time = rof_interval
	timer_rof.timeout.connect(_on_timer_rof_timeout)

func attempt_shoot():
	if can_shoot:
		shoot()
		
		if shoot_particle_scene:
			var instance = MattohaSystem.CreateInstance(shoot_particle_scene.resource_path)
			instance.position = barrel.global_position
			instance.rotation = barrel.global_rotation
			MattohaSystem.Client.LobbyNode.add_child(instance)
			# var new_particles = shoot_particle_scene.instantiate()
			# Game.deploy_instance(new_particles, barrel.global_position)
			# new_particles.global_transform = barrel.global_transform
		
		can_shoot = false
		timer_rof.start()
		position.y -= gun_kickback

func shoot():
	deploy_projectile()

func deploy_projectile(angle: float=0.0, speed_mult: float=1.0):
	if !is_instance_valid(barrel):
		barrel = self
	var new_projectile: Projectile = MattohaSystem.CreateInstance(projectile.resource_path)
	new_projectile.position = barrel.global_position
	var forward: Vector2 = barrel.global_transform.x
	var projectile_velocity: Vector2 = forward * projectile_speed
	var radian_angle := deg_to_rad(projectile_spread)
	projectile_velocity = projectile_velocity.rotated(randf_range( - radian_angle, radian_angle))
	projectile_velocity = projectile_velocity.rotated(deg_to_rad(angle))
	projectile_velocity *= speed_mult
	new_projectile.velocity = projectile_velocity
	if !can_hit_shooter and is_instance_valid(holder):
		new_projectile.add_exception(holder.get_hurtbox())

	# Game.deploy_instance(new_projectile, barrel.global_position)
	MattohaSystem.Client.LobbyNode.add_child(new_projectile)

	can_shoot = false
	timer_rof.start()
	
	return new_projectile

func get_activated():
	super()
	attempt_shoot()

func reload():
	can_shoot = true
	timer_rof.stop()


func _on_timer_rof_timeout():
	can_shoot = true
