extends Node


const maps = preload("res://data/maps/maps.tres")


func get_map_from_name(what: String) -> MapData:
	for i in maps.load_all():
		if i.name.to_lower() == what.to_lower():
			return i
	return null
