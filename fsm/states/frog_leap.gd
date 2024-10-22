@tool
extends State


@export var leap_velocity: Vector2 = Vector2(300, -300)
## The entity will be able to jump this much higher or lower than its current height
@export var allowed_height_variance: float = 128
## The entity can jump this far but no further
@export var max_distance: float = 512

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


func jump():
	var target_position: Vector2 = find_valid_platform()
	var relative_position: Vector2 = target_position - father.global_position
	
	if false:
		print( "Frog %s jumping %s" % [father.name, relative_position.round()] )
	
	if abs(relative_position.x) < 16:
		flipped = !flipped
	else:
		father.velocity = leap_velocity
		
		var duration: float = get_jump_duration(relative_position.y)
		if duration > 0.1:
			var dx: float = relative_position.x
			father.velocity.x = dx/duration

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
	
	if abs(xtime - ytime) < 0.2:
		return true
	return false

func find_valid_platform() -> Vector2:
	var raycast: RayCast2D = RayCast2D.new()
	raycast.target_position = Vector2(0, allowed_height_variance*2)
	raycast.collision_mask = 4
	father.add_child(raycast)
	raycast.position.y = -allowed_height_variance
	
	var centre: float = max_distance/2
	var xinterval: float = 8
	for i in range(max_distance / xinterval / 2):
		raycast.position.x = centre + i*xinterval
		if flipped: raycast.position *= -1
		raycast.force_raycast_update()
		if raycast.is_colliding():
			if is_point_on_arc(raycast.get_collision_point()):
				father.remove_child(raycast)
				raycast.queue_free()
				return raycast.get_collision_point()
		
		raycast.position.x = centre - i*16
		if flipped: raycast.position *= -1
		raycast.force_raycast_update()
		if raycast.is_colliding():
			if is_point_on_arc(raycast.get_collision_point()):
				father.remove_child(raycast)
				raycast.queue_free()
				return raycast.get_collision_point()
	
	father.remove_child(raycast)
	raycast.queue_free()
	return father.global_position
