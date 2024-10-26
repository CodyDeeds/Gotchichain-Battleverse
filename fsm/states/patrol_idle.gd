@tool
extends State


## The maximum distatnce that this entity will walk in one go
@export var max_distance: float = 256
## It will select this many random positions, and if one of them is valid it'll go there.
## If none are valid then it'll not go anywhere
@export var walk_attempts: int = 16
## Chance per frame that this entity walks somewhere
@export var walk_chance: float = 0.01
## The height of the entity's origin from the floor
## Used for checking for the existence of floors so that areas can be confirmed as walkable
@export var entity_height_from_floor: float = 32


func _step(delta: float):
	super(delta)
	
	if randf() < walk_chance:
		attempt_walk()


func attempt_walk():
	for i in range(walk_attempts):
		var this_position: float = randf_range(-max_distance, max_distance)
		if attempt_walk_to_position(this_position):
			break

func attempt_walk_to_position(where: float):
	if is_position_valid(where):
		var i = 0
		
		# Ensuring it is possible for the entity to get from its current position to the target position
		while abs(i) < abs(where):
			i += sign(where)*16
			
			if !is_position_valid(i):
				return false
		
		enter_next_state()
		fsm.current_state.target_position = father.global_position.x + where
		return true

func is_position_valid(where: float) -> bool:
	var has_floor: bool = false
	var has_wall: bool = false
	
	var raycast: RayCast2D = RayCast2D.new()
	raycast.collision_mask = 4
	raycast.target_position = Vector2(0, 8)
	father.add_child(raycast)
	raycast.position = Vector2(where, entity_height_from_floor-4)
	raycast.force_raycast_update()
	has_floor = raycast.is_colliding()
	father.remove_child(raycast)
	raycast.queue_free()
	
	var shapecast: ShapeCast2D = ShapeCast2D.new()
	shapecast.collision_mask = 4
	shapecast.target_position = Vector2()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = 4
	shapecast.shape = circle
	father.add_child(shapecast)
	shapecast.position = Vector2(where, entity_height_from_floor-6)
	shapecast.force_shapecast_update()
	has_wall = shapecast.is_colliding()
	father.remove_child(shapecast)
	shapecast.queue_free()
	
	return has_floor and !has_wall
