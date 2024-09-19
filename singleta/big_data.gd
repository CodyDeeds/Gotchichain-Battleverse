extends Node


const maps = preload("res://data/maps/maps.tres")


func get_map_from_name(what: String) -> MapData:
	for i in maps.load_all():
		if i.name.to_snake_case() == what.to_snake_case():
			return i
	return null
