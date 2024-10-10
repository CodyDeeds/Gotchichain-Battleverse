extends PathFollow2D

## Position along the path [0-1] where this element starts its cycle
@export var start: float = 0
## Furthest position along the path [0-1] that this element reaches
@export var end: float = 1
## Amount of time required for this element to complete one cycle
@export var interval: float = 8
## Position in its cycle [0-1] where this element starts
@export var phase: float = 0

## Centre of this element's movement - its average position
var centre: float = 0.5
## Maximum distance this element reaches from the centre
var amplitude: float = 0.5


func _ready() -> void:
	setup_position_variables()

func _process(delta: float) -> void:
	phase += delta / interval
	move_to_position()


func setup_position_variables():
	centre = (start + end)/2
	amplitude = (end - start)/2

func move_to_position():
	var actual_phase: float = phase * 2*PI
	var pos: float = -cos(actual_phase)
	progress_ratio = centre + pos*amplitude
