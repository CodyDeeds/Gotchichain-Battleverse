@tool
extends State


@export var leap_velocity: Vector2 = Vector2(300, -300)
## The entity will be able to jump this much lower than its current height
@export var allowed_drop: float = 128
## The entity can jump no less than this distance
@export var min_distance: float = 64
## The entity can jump this far but no further
@export var max_distance: float = 256

var flipped: bool = false


func _enter():
	super()
	
	#father.velocity = leap_velocity
	#if flipped:
		#father.velocity.x *= -1
	jump()

func _step(delta: float):
	super(delta)
	
	if age > 0.1 and father.is_on_floor():
		enter_next_state()

func _exit():
	super()
	
	father.velocity = Vector2()


func flip_at_wall():
	var raycast: RayCast2D = RayCast2D.new()
	raycast.target_position = Vector2(24, 0)
	raycast.collision_mask = 4
	if flipped: raycast.target_position.x *= -1
	father.add_child(raycast)
	raycast.force_raycast_update()
	
	if raycast.is_colliding():
		flipped = !flipped
	
	father.remove_child(raycast)
	raycast.queue_free()

func jump():
	flip_at_wall()
	var target_position: Vector2 = find_valid_platform()
	var relative_position: Vector2 = target_position - father.global_position
	
	if abs(relative_position.x) < 16:
		flipped = !flipped
		target_position = find_valid_platform()
		relative_position = target_position - father.global_position
		if abs(relative_position.x) < 16:
			enter_next_state()
			return
	
	father.velocity = leap_velocity
	var duration: float = get_jump_duration(relative_position.y)
	if duration > 0.1:
		var dx: float = relative_position.x
		father.velocity.x = dx/duration

func get_jump_max_height() -> float:
	var u = leap_velocity.y
	var a = father.gravity
	return - (u*u) / (2*a)

func get_jump_duration(height_increase: float = 0) -> float:
	var u = leap_velocity.y
	var s = height_increase
	var a = father.gravity
	return (-u + sqrt(u*u + 2*a*s)) / a

func is_point_on_arc(where: Vector2) -> bool:
	var relative_position: Vector2 = where - father.global_position
	var dx: float = abs(relative_position.x)
	var xtime: float = dx / abs(leap_velocity.x)
	var ytime: float = get_jump_duration(relative_position.y)
	
	if abs(xtime - ytime) < 0.4:
		return true
	return false

func find_valid_platform() -> Vector2:
	var distance_range: float = max_distance - min_distance
	var centre: float = (max_distance + min_distance)/2
	if flipped:
		centre *= -1
	var xinterval: float = 16
	for i in range(distance_range / xinterval / 2):
		var collision_point: Vector2
		
		collision_point = find_valid_platform_at( centre + i*xinterval )
		if collision_point != father.global_position:
			return collision_point
		
		collision_point = find_valid_platform_at( centre - i*xinterval )
		if collision_point != father.global_position:
			return collision_point
	
	return father.global_position

## Position relative to father
func find_valid_platform_at(xpos: float) -> Vector2:
	var raycast: RayCast2D = RayCast2D.new()
	var max_height: float = get_jump_max_height()
	raycast.target_position = Vector2(0, allowed_drop - max_height)
	raycast.collision_mask = 4
	father.add_child(raycast)
	raycast.position.x = xpos
	raycast.position.y = max_height
	raycast.force_raycast_update()
	
	while raycast.is_colliding():
		var collision_point: Vector2 = raycast.get_collision_point()
		
		father.remove_child(raycast)
		raycast.queue_free()
		return collision_point
		
		#raycast.target_position.y -= (collision_point.y - raycast.global_position.y)
		#raycast.global_position = collision_point
		#raycast.force_raycast_update()
		#if raycast.target_position.y < 8:
			#break
	
	father.remove_child(raycast)
	raycast.queue_free()
	return father.global_position
