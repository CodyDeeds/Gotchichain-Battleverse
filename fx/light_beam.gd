@tool
extends Node2D


@export var height: float = 64:
	set(what):
		height = what
		deploy_polygon()
@export var length: float = 512:
	set(what):
		length = what
		deploy_polygon()
@export var angle: float = 45:
	set(what):
		angle = what
		deploy_polygon()
@export var texture: Texture2D = null:
	set(what):
		texture = what
		deploy_polygon()


func _ready() -> void:
	deploy_polygon()


func deploy_polygon():
	if !is_inside_tree():
		return
	
	# Points
	var points: PackedVector2Array = PackedVector2Array()
	
	points.append(Vector2(0, -height/2))
	points.append(Vector2(0,  height/2))
	
	var end: Vector2 = Vector2(length, 0).rotated(deg_to_rad(angle))
	
	points.append(end + Vector2(0, height/2))
	points.append(end - Vector2(0, height/2))
	
	%polygon.polygon = points
	
	# UVs
	if texture:
		var uvs: PackedVector2Array = PackedVector2Array()
		
		uvs.append(Vector2(0, texture.get_height()))
		uvs.append(Vector2(0, 0))
		uvs.append(Vector2(texture.get_width(), 0))
		uvs.append(Vector2(texture.get_width(), texture.get_height()))
		
		%polygon.uv = uvs
