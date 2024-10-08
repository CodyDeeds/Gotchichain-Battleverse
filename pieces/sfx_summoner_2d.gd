@tool
@icon("res://pieces/sfx_summoner_2d.png")
class_name SFXSummoner2D
extends Node2D


@export var auto_play: bool = false
@export var one_shot: bool = false
@export_group("SFX")
@export var sfx: StringName = &""
@export_range(0, 2) var volume: float = 1
@export var minimum_pitch: float = 1:
	set(what):
		minimum_pitch = what
		if maximum_pitch < minimum_pitch:
			maximum_pitch = minimum_pitch
@export var maximum_pitch: float = 1:
	set(what):
		maximum_pitch = what
		if minimum_pitch > maximum_pitch:
			minimum_pitch = maximum_pitch


func _ready() -> void:
	if auto_play:
		activate()


func activate():
	var new_sfx: SFX2D = GlobalSound.play_sfx_2d(sfx, global_position) as SFX2D
	new_sfx.volume_db = linear_to_db(volume)
	var pitch: float = randf_range(minimum_pitch, maximum_pitch)
	new_sfx.pitch_scale = pitch
	
	if one_shot:
		queue_free()
