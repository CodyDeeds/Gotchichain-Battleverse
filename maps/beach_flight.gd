extends World


@export var button_interval := 10.0


func activate_lasers():
	for i in %lasers.get_children():
		i.activate()
	
	var new_timer := get_tree().create_timer(button_interval)
	new_timer.timeout.connect( %laser_button.enable )
