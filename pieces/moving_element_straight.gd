extends PathFollow2D


## Speed along the path in full path lengths per second
@export var speed: float = 0.125
## Whether this element should be destroyed when it reaches either the start or end of its path
@export var destroy_on_finish: bool = true


func _process(delta: float) -> void:
	var next_progress: float = progress_ratio + speed*delta
	if next_progress > 1.0 or next_progress < 0.0:
		if destroy_on_finish:
			queue_free()
	progress_ratio = next_progress


