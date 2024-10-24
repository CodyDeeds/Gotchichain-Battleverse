extends Node2D


## Number of explosions to be spawned
@export var explosion_count: int = 8
## Delay between one explosion and the next
@export var explosion_delay: float = 0.1
## How far away the explosions can spawn
@export var explosion_reach: float = 48
## Scale of explosions at centre
@export var max_scale: float = 2.0
## Scale of explosions at maximum distance
@export var min_scale: float = 0.5


func _ready() -> void:
	activate()
	%timer.start(explosion_delay)


func activate():
	var distance_ratio: float = randf()
	%shaker.activate()
	%spawner.offset = Vector2( distance_ratio*explosion_reach, 0 ).rotated( randf() * 2*PI )
	%spawner.activate()
	var this_scale: float = lerp(max_scale, min_scale, distance_ratio)
	%spawner.scale = Vector2(this_scale, this_scale)
	GlobalSound.play_sfx_2d(&"blast_small", global_position)
	explosion_count -= 1
	if explosion_count <= 0:
		queue_free()
