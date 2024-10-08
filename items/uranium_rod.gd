@tool
extends Item


@export var damage: float = 1
## Hold the rod within this range of an enemy in order to hit them
@export var hit_range: float = 96
## Amount of time one needs to hold the rod near an enemy in order to hit them
@export var hit_delay: float = 2

var current_hit_delay: float = hit_delay


func _process(delta: float) -> void:
	super(delta)
	
	var valid_targets: Array = get_valid_targets()
	if valid_targets.size() == 0:
		current_hit_delay = hit_delay
		%glow_charge.hide()
	else:
		current_hit_delay -= delta
		%glow_charge.show()
		var ratio: float = 1 - current_hit_delay / hit_delay
		if current_hit_delay <= 0:
			for this_target in valid_targets:
				this_target.take_damage(damage)
			$flash_animator.play("flash")
			current_hit_delay = hit_delay
		
		%glow_charge.modulate.a = ratio
		var glow_scale: float = lerp(.1, .2, ratio + randf_range(0, 0.02))
		%glow_charge.scale = Vector2(glow_scale, glow_scale)


func get_valid_targets():
	var output: Array = []
	
	if is_instance_valid(holder):
		for this_player in get_tree().get_nodes_in_group("players"):
			if this_player != holder:
				var this_d2: float = this_player.global_position.distance_squared_to(global_position)
				if this_d2 < hit_range*hit_range:
					output.append(this_player)
	
	return output
