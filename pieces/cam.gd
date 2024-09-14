class_name MainCamera
extends Camera2D

@export var move_speed := 5.0
@export var zoom_speed := 10.0
## Amount of space around players that needs to remain visible
@export var border := 256.0

func _ready() -> void:
	Game.cam = self

func _process(delta: float) -> void:
	centre_on_players(delta)
	zoom_to_players(delta)


func shake(amount: float, direction: float = randf_range(0, 2*PI)):
	position += Vector2(amount, 0).rotated(direction)

func get_average_player_position() -> Vector2:
	var average_position: Vector2 = Vector2()
	var player_count := 0
	
	for this_player: Player in get_tree().get_nodes_in_group("players"):
		average_position += this_player.global_position
		player_count += 1
	
	if player_count > 1:
		average_position /= player_count
	
	return average_position

func centre_on_players(delta: float):
	global_position = global_position.lerp(get_average_player_position(), delta * move_speed)

func zoom_to_players(delta: float):
	var default_size: Vector2 = get_viewport_rect().size
	var rect_start: Vector2 = global_position - default_size / 2
	var rect_end: Vector2 = global_position + default_size / 2
	
	for this_player: Player in get_tree().get_nodes_in_group("players"):
		var this_pos: Vector2 = this_player.global_position
		
		if this_pos.x < rect_start.x: rect_start.x = this_pos.x
		if this_pos.y < rect_start.y: rect_start.y = this_pos.y
		if this_pos.x > rect_end.x: rect_end.x = this_pos.x
		if this_pos.y > rect_end.y: rect_end.y = this_pos.y
	
	var target_size: Vector2 = rect_end - rect_start + Vector2(border, border)
	var ratios: Vector2 = target_size / default_size
	var target_zoom: float = 1 / max(ratios.x, ratios.y)
	zoom = zoom.lerp(Vector2(target_zoom, target_zoom), delta * zoom_speed)

func get_area():
	var size: Vector2 = get_viewport().get_visible_rect().size
	size /= zoom
	return Rect2(global_position - size/2, size)
