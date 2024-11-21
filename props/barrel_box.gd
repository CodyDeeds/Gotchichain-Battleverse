extends StaticBody2D


## Amount of time in seconds that this box hangs open before closing itself to be reactivated
@export var open_duration := 1.5

var is_enabled := true

signal enabled


func activate():
	if is_enabled:
		%animator.play(&"open")
		is_enabled = false

func spawn_barrel():
	var new_barrel = %spawner.activate()
	new_barrel.add_collision_exception_with(self)
	new_barrel.propagate_exceptions_to_wall_detector()
	
	var new_timer := get_tree().create_timer(open_duration)
	new_timer.timeout.connect(shut)

func shut():
	%animator.play(&"shut")

func enable():
	is_enabled = true
	enabled.emit()
