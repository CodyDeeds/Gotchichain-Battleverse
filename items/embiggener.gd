extends Item


@export var default_scale := Vector2(1, 1)
@export var embiggenation := Vector2(.5, .5)

var scalables: Array[Node2D] = []


func _ready() -> void:
	scalables = [%sprite, %shape, %player_detector]

func _process(delta: float) -> void:
	super(delta)
	
	normalise_scale(delta)


func normalise_scale(delta: float):
	for i in scalables:
		i.scale = i.scale.lerp(default_scale, delta)

func get_activated():
	super()
	
	for i in scalables:
		i.scale += embiggenation
