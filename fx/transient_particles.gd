extends CPUParticles2D


func _ready() -> void:
	one_shot = true
	emitting = true
	var timer := get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)
