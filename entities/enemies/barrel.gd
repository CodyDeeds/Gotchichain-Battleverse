extends Enemy


@export var speed := 400.0

var hvelocity: float


func _ready() -> void:
	hvelocity = speed

func _process(delta: float) -> void:
	super(delta)
	velocity.x = hvelocity

func _physics_process(delta: float) -> void:
	var previous_velocity := velocity
	
	super(delta)
	
	if previous_velocity.y > 20:
		for i in get_slide_collision_count():
			var this_collision := get_slide_collision(i)
			if this_collision.get_normal().y < 0:
				hvelocity *= -1
				return
	
	if is_about_to_hit_wall():
		hvelocity *= -1
		return


func is_about_to_hit_wall() -> bool:
	%wall_detector.target_position.x = sign(hvelocity) * 8
	%wall_detector.force_shapecast_update()
	return %wall_detector.is_colliding()

func propagate_exceptions_to_wall_detector():
	%wall_detector.clear_exceptions()
	for this_exception in get_collision_exceptions():
		%wall_detector.add_exception(this_exception)
