extends Projectile


## When created, this bomb moves upward with this speed
@export var jump_speed := 600.0
## Amount that this projectile accelerates due to gravity
@export var gravity_acceleration := 500.0
## Changes to an alternative frame if the vertical speed is greater than this
@export var speed_threshhold := 200.0
## Speed with which the sprite flashes
@export var animation_speed := 10.0

const explosion_scene = preload("res://projectiles/explosion.tscn")


func _ready() -> void:
	super()
	
	velocity.y = -jump_speed

func _process(delta: float) -> void:
	super(delta)
	velocity.y += gravity_acceleration * delta
	
	if velocity.y < -speed_threshhold:
		%sprite.frame = 0
	elif velocity.y < speed_threshhold:
		%sprite.frame = 2
	else:
		%sprite.frame = 4
	
	var interval := 2.0 / animation_speed
	if fmod(age, interval) < interval/2:
		%sprite.frame += 1


func die():
	super()
	
	var new_explosion = Game.create_instance(explosion_scene)
	new_explosion.damage = 1
	Game.deploy_instance(new_explosion, global_position)

