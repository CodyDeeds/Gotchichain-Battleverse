extends Area2D


var value: int = 150
var velocity: Vector2 = Vector2()
var acceleration: Vector2 = Vector2(0, 500)
var duration: float = 10


func _ready() -> void:
	body_entered.connect(_on_crash)

func _process(delta: float) -> void:
	position += velocity * delta
	velocity += acceleration * delta
	
	duration -= delta
	if duration <= 0:
		queue_free()


func _on_crash(_body):
	Game.deploy_coin_payload.call_deferred(value, global_position)
	queue_free()
