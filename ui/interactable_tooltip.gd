extends Node2D

var interactable: Interactable2D = null: set = set_interactable


func _ready() -> void:
	%animator.play(&"arrive")


func set_interactable(what: Interactable2D):
	%title.text = what.title
	%verb.text = what.verb
