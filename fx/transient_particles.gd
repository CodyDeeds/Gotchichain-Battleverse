extends CPUParticles2D


@export var autoplay := true


func _ready() -> void:
	if autoplay:
		activate()


func activate():
	one_shot = true
	emitting = true
	var timer := get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)
