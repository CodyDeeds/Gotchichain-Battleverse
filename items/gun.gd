@tool
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
var shoot_veto := false
var shots_taken: int = 0

func _ready() -> void:
	add_child(timer_rof)
	timer_rof.wait_time = rof_interval
	timer_rof.timeout.connect(_on_timer_rof_timeout)

func attempt_shoot():
	if can_shoot and !shoot_veto:
		shoot()
		
		if shoot_particle_scene:
			#var instance = MattohaSystem.CreateInstance(shoot_particle_scene.resource_path)
			#instance.position = barrel.global_position
			#instance.rotation = barrel.global_rotation
			#MattohaSystem.Client.LobbyNode.add_child(instance)
			var new_particles = Game.create_instance(shoot_particle_scene)
			Game.deploy_instance(new_particles, barrel.global_position)
			new_particles.global_transform = barrel.global_transform
		
		can_shoot = false
		timer_rof.start()
		position.y -= gun_kickback

func shoot():
	deploy_projectile()

func deploy_projectile(angle: float=0.0, speed_mult: float=1.0):
	if !is_instance_valid(barrel):
		barrel = self
	var new_shot: Node2D = Game.create_instance(projectile)
	
	if new_shot is Projectile:
		#var new_shot: Projectile = MattohaSystem.CreateInstance(projectile.resource_path)
		new_shot.position = barrel.global_position
		var forward: Vector2 = barrel.global_transform.x
		var projectile_velocity: Vector2 = forward * projectile_speed
		var radian_angle := deg_to_rad(projectile_spread)
		var rng_factor: float = sin( round(global_position.x + global_position.y*7) + shots_taken )
		projectile_velocity = projectile_velocity.rotated(radian_angle * rng_factor)
		projectile_velocity = projectile_velocity.rotated(deg_to_rad(angle))
		projectile_velocity *= speed_mult
		new_shot.velocity = projectile_velocity
		if !can_hit_shooter and is_instance_valid(holder):
			new_shot.add_exception(holder.get_hurtbox())
	
	if new_shot is Laser:
		new_shot.position = barrel.global_position
		var forward: Vector2 = barrel.global_transform.x
		var radian_angle := deg_to_rad(projectile_spread)
		var rng_factor: float = sin( round(global_position.x + global_position.y*7) + shots_taken )
		forward = forward.rotated(radian_angle * rng_factor)
		forward = forward.rotated(deg_to_rad(angle))
		new_shot.direction = forward
		
		if !can_hit_shooter and is_instance_valid(holder):
			new_shot.add_exception(holder.get_hurtbox())
	
	Game.deploy_instance(new_shot, barrel.global_position)
	#MattohaSystem.Client.LobbyNode.add_child(new_shot)
	
	can_shoot = false
	timer_rof.start()
	
	shots_taken += 1
	
	return new_shot

func get_activated():
	super()
	attempt_shoot()

func reload():
	can_shoot = true
	timer_rof.stop()


func _on_timer_rof_timeout():
	can_shoot = true
