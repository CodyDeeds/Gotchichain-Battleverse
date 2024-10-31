extends Node2D


@export var lavafall_width_multiplier: float = 0: set = set_lavafall_width_multiplier

# Keys = nodes; values = original widths
var lavafalls: Dictionary = {}


func _ready() -> void:
	register_lavafalls()
	set_lavafall_width_multiplier(0)


func register_lavafalls():
	for i in Util.get_all_descendents(self):
		if i is Polygon2D and "width" in i:
			lavafalls[i] = i.width

func summon_lava():
	%animator.play("summon_lava")

func dismiss_lava():
	%animator.play("dismiss_lava")


func set_lavafall_width_multiplier(what: float):
	lavafall_width_multiplier = what
	for this_lavafall in lavafalls:
		this_lavafall.width = lavafalls[this_lavafall] * what
