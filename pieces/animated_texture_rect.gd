@tool
class_name AnimatedTextureRect
extends TextureRect


@export var frames: SpriteFrames = null
@export var speed_scale: float = 1
@export var animation_name := &"default"

var actual_frame: float = 0


func _process(delta: float) -> void:
	actual_frame += frames.get_animation_speed(animation_name) * delta
	actual_frame = fposmod(actual_frame, get_total_frames())
	show_current_frame()


func show_current_frame():
	var this_texture: Texture = frames.get_frame_texture(animation_name, int(actual_frame))
	texture = this_texture

func get_total_frames() -> int:
	if frames:
		return frames.get_frame_count(animation_name)
	return 1
