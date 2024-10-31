extends World


func _on_button_activated() -> void:
	var animation_duration: float = %lava_animator.get_animation("arise").length
	var tween := create_tween()
	%lava_animator.play("arise")
	%cave.summon_lava()
	tween.tween_interval(animation_duration)
	tween.tween_callback( %lava_animator.play_backwards.bind("arise") )
	tween.tween_callback( %cave.dismiss_lava )
	tween.tween_interval(animation_duration)
	tween.tween_callback( %lava_button.enable )
