@icon("res://projectiles/projectile.png")
class_name Projectile
extends Hitbox

@export_group("Life")
## Number of times this projectile can hit an enemy before dissipating
@export var hits_left := 1
## Amount of time this projectile lasts before dissipating
@export var duration := 5.0
## Whether this projectile can pass through walls
@export var through_walls := false
## Whether or not to use a raycast to check collisions
@export var use_raycast := true
## Scene created when projectile is destroyed
@export_group("Resources")
@export var death_scene: PackedScene = null
## SFX to play when the projectile is shot
@export var creation_sound: StringName = &""
## SFX to play when the projectile is destroyed
## Left empty, it is the same as [code]creation_sound[/code]
@export var death_sound: StringName = &""
## If less than this much time has passed since creation, the death sound will not play
@export var death_sound_min_delay: float = 0.5

var raycast := RayCast2D.new()
var wallcast := RayCast2D.new()
var velocity := Vector2()
var acceleration := Vector2()
var age: float = 0
var dead := false

signal expired
signal crashed


func _ready() -> void:
	super()
	
	if !through_walls:
		set_collision_mask_value(3, true)
		
		body_entered.connect(_on_body_entered)
		area_entered.connect(_on_area_entered)
	
	add_child(raycast)
	raycast.position = Vector2()
	raycast.collide_with_areas = true
	raycast.collide_with_bodies = false
	raycast.set_collision_mask_value(1, false)
	raycast.set_collision_mask_value(6, true)
	
	add_child(wallcast)
	wallcast.position = Vector2()
	raycast.set_collision_mask_value(1, false)
	raycast.set_collision_mask_value(3, true)
	
	GlobalSound.play_sfx_2d(creation_sound, global_position)

func _process(delta: float) -> void:
	age += delta
	
	velocity += acceleration * delta
	var predicted_target: Hurtbox = null
	if use_raycast:
		raycast.global_rotation = 0
		raycast.target_position = velocity * delta
		raycast.force_raycast_update()
		
		if raycast.is_colliding():
			predicted_target = raycast.get_collider()
			if is_instance_valid(predicted_target):
				if predicted_target.is_compatible_hitbox(self):
					predicted_target.get_hit_by(self)
	
	if !dead:
		position += velocity * delta
	
	duration -= delta
	if duration <= 0:
		expired.emit()
		die()


func hit_being(what):
	super(what)
	
	hits_left -= 1
	if hits_left <= 0:
		die()

func die():
	dead = true
	active = false
	
	if death_scene:
		#if (!multiplayer.is_server()):
			var instance = Game.create_instance(death_scene)
			Game.deploy_instance(instance, global_position)
	
	if age >= death_sound_min_delay:
		if death_sound == &"":
			GlobalSound.play_sfx_2d(creation_sound, global_position)
		else:
			GlobalSound.play_sfx_2d(death_sound, global_position)

	queue_free()

func _on_body_entered(_what: Node2D):
	if !through_walls:
		crashed.emit()
		die()

func _on_area_entered(what: Node2D):
	if what is Hurtbox and what.is_compatible_hitbox(self):
		hit_being(what.father)
