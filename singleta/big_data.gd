extends Node


var items: Dictionary = {}

const maps = preload("res://data/maps/maps.tres")
const all_items = preload("res://items/_all_items.tres")


func _ready() -> void:
	register_items()


func register_items():
	for this_item in all_items.load_all():
		var new_item = this_item.instantiate()
		items[new_item.get_id()] = this_item

func get_all_items():
	return items.values()


func get_map_from_name(what: String) -> MapData:
	for i in maps.load_all():
		if i.name.to_snake_case() == what.to_snake_case():
			return i
	return null
