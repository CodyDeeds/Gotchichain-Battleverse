@icon("res://pieces/destroyer.png")
class_name Destroyer
extends Node


func activate():
	get_parent().queue_free()
