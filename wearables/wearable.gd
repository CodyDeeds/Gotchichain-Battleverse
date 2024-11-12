class_name Wearable
extends Resource


## Internal ID of this wearable. If not specified, the snake_case of [code]name[/code] will be used
@export var id := ""
## User-facing name of this wearable
@export var name := ""
## Texture of this wearable
@export var sprite: Texture2D = null
## Sprite will be moved over by this amount
@export var offset: Vector2 = Vector2()


func get_id() -> String:
	if id == "":
		return name.to_snake_case()
	else:
		return id
