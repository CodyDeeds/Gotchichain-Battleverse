@tool
class_name EnemySpawner
extends Node2D


enum MODE {
	TIMED,
	CHANCE,
	MANUAL
}

## The enemy to spawn
@export var enemy: PackedScene = null
## When does this spawn enemies
@export var mode := MODE.CHANCE:
	set(what):
		mode = what
		notify_property_list_changed()
## How much of the map's value is distributed to this spawner, to be further distributed to enemies
@export var value_weight: float = 1
## How much value to imbue each spawned enemy with. 
## If there is no value available, no enemy is spawned. 
## If there is some value available but not enough, the enemy is imbued with less value
@export var value_per_enemy := 100

var chance := 0.002
var interval := 8.0
var time_to_spawn := interval
var spawner := Spawner.new()
var value := 0


func _get_property_list() -> Array[Dictionary]:
	var output: Array[Dictionary] = []
	
	var interval_usage = PROPERTY_USAGE_NO_EDITOR
	var chance_usage = PROPERTY_USAGE_NO_EDITOR
	
	match mode:
		MODE.TIMED:
			interval_usage = PROPERTY_USAGE_DEFAULT
		
		MODE.CHANCE:
			chance_usage = PROPERTY_USAGE_DEFAULT
	
	output.append({
		"name": "interval",
		"type": TYPE_FLOAT,
		"usage": interval_usage
	})
	output.append({
		"name": "chance",
		"type": TYPE_FLOAT,
		"usage": chance_usage
	})
	
	return output


func _init() -> void:
	add_to_group(&"value_sources")

func _ready() -> void:
	if !Engine.is_editor_hint():
		spawner.scene = enemy
		add_child(spawner)

func _process(delta: float) -> void:
	if !Engine.is_editor_hint():
		match mode:
			MODE.TIMED:
				time_to_spawn -= delta
				while time_to_spawn <= 0:
					time_to_spawn += interval
					activate()
			MODE.CHANCE:
				var roll := randf()
				while roll < chance:
					roll += 1
					activate()


func activate():
	Game.distribute_value()
	if value > 0:
		var new_enemy = spawner.activate()
		var imbuement = min(value, value_per_enemy)
		new_enemy.value = imbuement
		value -= imbuement
		
		if "source" in new_enemy:
			new_enemy.source = self
