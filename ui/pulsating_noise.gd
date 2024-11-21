@tool
extends Sprite2D


## Amount this noise rotates in degrees per second
@export var rotation_speed := 30.0
## Amount the size increases and decreases by. e.g. amplitude of 0.3 leads to scales in the range of 0.7 - 1.3
@export var scale_amplitude := 0.3
## Amount of time over which the scale changes complete one cycle
@export var scale_interval := 10.0

@export var pulsate_amplitude := 0.05

@export var pulsate_interval := 13.0

@export var gradient_offset := 0.0

@export var gradient: Gradient = null: set = set_gradient


var _gradient: Gradient = null
var age := 0.0


func _ready() -> void:
	assign_gradient(true)

func _process(delta: float) -> void:
	age += delta
	rotation += deg_to_rad(rotation_speed) * delta
	
	change_scale()
	change_pulsation()


func change_scale():
	var scale_phase := fmod(age / scale_interval, 1) * 2*PI
	var _scale := 1 + sin(scale_phase) * scale_amplitude
	scale = Vector2(_scale, _scale)

func change_pulsation():
	if !gradient:
		return
	
	var pulaste_phase := fmod(age / pulsate_interval, 1) * 2*PI
	var pulsation := sin(pulaste_phase) * pulsate_amplitude
	
	assign_gradient()
	for i in range(_gradient.offsets.size()):
		_gradient.offsets[i] = gradient.offsets[i] + pulsation - gradient_offset

func assign_gradient(force_recreate: bool = false):
	if !gradient:
		return
	
	_gradient = gradient.duplicate()
	if !(texture is NoiseTexture2D) or force_recreate:
		texture = NoiseTexture2D.new()
		texture.seamless = true
		texture.noise = FastNoiseLite.new()
	texture.color_ramp = _gradient


func set_gradient(what: Gradient):
	gradient = what
	assign_gradient(true)
