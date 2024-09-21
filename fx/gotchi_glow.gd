@tool
extends Node2D


@export var colour: Color = Color(1, 1, 1, 1):
	set(what):
		colour = what
		%glow0.self_modulate = what
		%glow1.self_modulate = what



