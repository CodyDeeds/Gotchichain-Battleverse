extends Enemy


func _ready() -> void:
	super()
	
	tree_exiting.connect(_on_tree_exiting)


func set_flip(what: bool):
	%leap.flipped = what


func _on_hitbox_hit() -> void:
	velocity.y -= 50

func _on_tree_exiting():
	if is_instance_valid(%particulation):
		%particulation.reparent( Game.world )
