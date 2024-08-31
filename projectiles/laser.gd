class_name Laser
extends Projectile


## The laser will reach no further than this
@export var max_length: float = 999999
## The width of the beam
@export var width: float = 4

@export_group("Visuals")
## Particles that will appear at the start of the beam
@export var start_fx_scene: PackedScene = null
## Particles that will appear at the end of the beam
@export var end_fx_scene: PackedScene = null
## Particles that will cover the length of the beam
## Prefer to use one of the Particles2D nodes, as they'll be stretched along the beam's length
@export var line_fx_scene: PackedScene = null
## If [code]line_fx_scene[/code] is a particle scene, this is the
## average amount of particles per pixel of laser length
@export var particle_density: float = 0.05
## Scene that forms the visualisation of the beam
## Prefer to use a Line2D, as it'll be stretched along the beam's length
@export var line_scene: PackedScene = null
## Whether or not [code]line_scene[/code] should fade out over the duration of the laser's existence
@export var fade_laser: bool = true

var laser_vector: Vector2 = Vector2()


func _ready() -> void:
	# Overriding a lot of the default projectile behaviour
	setup_nodes()
	setup_line()
	setup_fx()

func _process(delta: float) -> void:
	# Overriding a lot of the default projectile behaviour
	duration -= delta
	if duration <= 0:
		die()


func setup_nodes():
	var new_raycast: RayCast2D = RayCast2D.new()
	add_child(new_raycast)
	new_raycast.global_rotation = 0
	new_raycast.target_position = velocity.normalized() * max_length
	new_raycast.collision_mask = 4
	cast(new_raycast)

func setup_fx():
	if start_fx_scene:
		var new_fx = start_fx_scene.instantiate()
		Game.deploy_instance(new_fx, global_position)
		new_fx.rotation = laser_vector.angle()
	if end_fx_scene:
		var new_fx = end_fx_scene.instantiate()
		Game.deploy_instance(new_fx, global_position + laser_vector)
		new_fx.rotation = laser_vector.angle() + PI
	if line_fx_scene:
		var new_fx = line_fx_scene.instantiate()
		Game.deploy_instance(new_fx, global_position + laser_vector/2)
		new_fx.rotation = laser_vector.angle()
		
		if new_fx is CPUParticles2D:
			new_fx.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
			new_fx.emission_rect_extents = Vector2(laser_vector.length()/2, width/2)
			new_fx.amount = particle_density * laser_vector.length()
		
		if new_fx is GPUParticles2D:
			var process_material: ParticleProcessMaterial = new_fx.process_material as ParticleProcessMaterial
			process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
			process_material.emission_box_extents = Vector3(laser_vector.length()/2, width/2, 0)
			new_fx.amount = particle_density * laser_vector.length()

func setup_line():
	if line_scene:
		var new_line = line_scene.instantiate()
		Game.deploy_instance(new_line, global_position)
		
		if new_line is Line2D:
			var points: PackedVector2Array = PackedVector2Array()
			points.append(laser_vector)
			points.append(Vector2())
			new_line.points = points
		
		get_tree().create_timer(duration).timeout.connect(new_line.queue_free)
		
		if fade_laser and new_line is CanvasItem:
			var tween: Tween = create_tween()
			tween.tween_property(new_line, "modulate", Color(1, 1, 1, 0), duration)

func cast(ray: RayCast2D):
	ray.force_raycast_update()
	var target_position: Vector2 = Vector2()
	
	if ray.is_colliding():
		target_position = ray.get_collision_point()
	else:
		# Limit the ray to the visible area for performance reasons
		var cam: MainCamera = Game.cam
		if is_instance_valid(cam):
			var dir: Vector2 = ray.target_position.rotated(ray.global_rotation).normalized()
			target_position = global_position
			
			var area: Rect2 = cam.get_area()
			while area.has_point(target_position):
				target_position += dir * 300
		else:
			target_position = global_position + ray.target_position.rotated(ray.global_rotation)
	
	
	var relative: Vector2 = (target_position - global_position) / 2
	
	var new_shape: CollisionShape2D = CollisionShape2D.new()
	var new_box: RectangleShape2D = RectangleShape2D.new()
	add_child(new_shape)
	new_shape.shape = new_box
	new_shape.global_position = global_position + relative
	new_box.size = Vector2(relative.length()*2, width)
	new_shape.rotation = relative.angle()
	
	laser_vector = relative*2
