@icon("res://pieces/transient_sprite.png")
class_name TransientSprite2D
extends AutoSprite2D


func _ready() -> void:
	super()
	finished.connect(queue_free)
