@tool
class_name StretchSprite2D
extends Sprite2D


@export_flags("Up", "Down", "Left", "Right") var stretch_direction: int = 0: set = set_stretch_direction


func update_stretches():
	clear_stretches()
	add_stretches()

func clear_stretches():
	for i in get_children():
		if i is Sprite2D:
			remove_child(i)
			i.queue_free()

func add_stretches():
	for i in range(4):
		if stretch_direction & int(pow(2, i)):
			add_stretch(i)

func add_stretch(direction: int = 0):
	var new_sprite := Sprite2D.new()
	new_sprite.texture = texture
	new_sprite.region_enabled = true
	var region: Rect2 = region_rect
	if !region_enabled:
		region = Rect2(Vector2(), texture.get_size())
	new_sprite.region_rect = region
	
	if direction == 0 or direction == 1:
		new_sprite.region_rect.size.y = 1
		new_sprite.scale.y = 1000000
	else:
		new_sprite.region_rect.size.x = 1
		new_sprite.scale.x = 1000000
	
	add_child(new_sprite)
	
	match direction:
		0:
			new_sprite.region_rect.position.y = 0
			new_sprite.position.y = -region.size.y/2 - 500000
		1:
			new_sprite.region_rect.position.y = region.end.y - 1
			new_sprite.position.y = region.size.y/2 + 500000
		2:
			new_sprite.region_rect.position.x = 0
			new_sprite.position.x = -region.size.x/2 - 500000
		3:
			new_sprite.region_rect.position.x = region.end.x - 1
			new_sprite.position.x = region.size.x/2 + 500000


func set_stretch_direction(what: int):
	stretch_direction = what
	update_stretches()
