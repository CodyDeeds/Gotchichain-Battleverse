extends Node


## All items - Key: item ID, Value: item as PackedScene
var items: Dictionary = {}
## All items arranged by pool. Key: Pool as int, Value: Array of item IDs
var item_pools: Dictionary = {}

const maps = preload("res://data/maps/maps.tres")
const all_items = preload("res://items/_all_items.tres")


func _ready() -> void:
	register_items()


func register_items():
	for this_item in all_items.load_all():
		var new_item: Item = this_item.instantiate()
		var item_id: String = new_item.get_id()
		for pool in new_item.pools:
			add_item_to_pool( item_id, pool )
		items[item_id] = this_item

func add_item_to_pool(item_id: String, pool: int):
	if !item_pools.has(pool):
		item_pools[pool] = []
	item_pools[pool].append(item_id)

func get_all_items():
	return items.values()

func get_random_item_from_pool(pool: int):
	if !item_pools.has(pool):
		push_error("Trying to get item from nonexistent pool %s" % pool)
		return
	var ids: Array = item_pools[pool]
	if ids.size() == 0:
		push_error("Item pool %s has no items" % pool)
		return
	var item_id: String = ids.pick_random()
	if !items.has(item_id):
		push_error("Attempting to get nonexistent item %s from pool %s" % [item_id, pool])
		return
	return items[item_id]


func get_map_from_name(what: String) -> MapData:
	for i in maps.load_all():
		if i.name.to_snake_case() == what.to_snake_case():
			return i
	return null
