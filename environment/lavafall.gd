@tool
extends Polygon2D


## Width of the flow
@export var width: float = 16: set = set_width
## Speed with which the flow emerges from its source
@export var velocity: Vector2 = Vector2(): set = set_velocity
## Amount the flow accelerates downward with each step
@export var gravity: float = 100: set = set_gravity
## Number of steps to calculate
@export var steps: int = 64: set = set_steps
## Amount to offset the texture by
@export var uv_offset: float = 0: set = set_uv_offset


func _ready() -> void:
	calculate_points()


func calculate_points():
	var points := PackedVector2Array()
	var uvs := PackedVector2Array()
	var polys = Array()
	
	var current_uv: float = uv_offset
	
	for i in range(steps + 1):
		var prev_position := get_point(i - 1)
		var this_position := get_point(i + 0)
		var next_position := get_point(i + 1)
		
		var from     := this_position - prev_position
		var   to     := next_position - this_position
		var from_dir := from.normalized()
		var   to_dir :=   to.normalized()
		# Assuming we can add the vectors and normalise it to approximate an average
		var dir := (from_dir + to_dir).normalized()
		var normal := dir.rotated(PI/2)
		
		points.append(this_position + normal * width/2)
		points.insert(0, this_position - normal * width/2)
		
		# Assign polygons
		# Using this i < steps conditional because e.g. 4 steps generates 5 pairs of vertices but only 4 polygons
		# So we skip the last polygon
		if i < steps:
			var this_poly := PackedInt32Array()
			
			this_poly.append(i)
			this_poly.append(i+1)
			this_poly.append(steps*2 - i)
			this_poly.append(steps*2 + 1 - i)
			
			polys.append(this_poly)
		
		# Add UVs
		if texture:
			uvs.append( Vector2(0, current_uv) )
			uvs.insert( 0, Vector2(float(texture.get_width()), current_uv) )
			
			current_uv += from.length()
	
	polygon = points
	uv = uvs
	polygons = polys

func get_point(which: int) -> Vector2:
	var output := Vector2()
	
	output.x = velocity.x * which
	output.y = velocity.y * which + gravity * which*(which+1) / 2
	
	return output


func set_width(what: float):
	width = what
	calculate_points()

func set_velocity(what: Vector2):
	velocity = what
	calculate_points()

func set_gravity(what: float):
	gravity = what
	calculate_points()

func set_steps(what: int):
	steps = what
	calculate_points()

func set_uv_offset(what: float):
	uv_offset = what
	calculate_points()
