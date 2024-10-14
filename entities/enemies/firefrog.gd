extends Enemy


func _ready() -> void:
	super()
	
	tree_exiting.connect(_on_tree_exiting)
	GlobalSound.play_sfx_2d(&"fireball_throw", global_position)


func set_flip(what: bool):
	%leap.flipped = what


func _on_hitbox_hit() -> void:
	velocity.y -= 50

func _on_tree_exiting():
	if is_instance_valid(%particulation):
		%particulation.reparent( Game.world )
