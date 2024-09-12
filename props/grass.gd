extends Node2D


func _on_player_detector_player_entered() -> void:
	var animation: StringName = &"wiggle_left"
	if randf() < 0.5:
		animation = &"wiggle_right"
	
	%animator.stop()
	%animator.play(animation)
