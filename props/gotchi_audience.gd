extends Node2D


func _ready() -> void:
	%animator.advance( randf() )
	%animator.speed_scale = randf_range(0.25, 0.5)
	%sprite.actual_frame = randi() % (%sprite.hframes*%sprite.vframes)
