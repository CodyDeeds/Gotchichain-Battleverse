extends Area2D


@export var continuously_report := true

var overlapping_players: Array[Player] = []

signal player_entered
signal player_exited
signal player_within

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if continuously_report and has_player():
		player_within.emit()


func has_player() -> bool:
	return overlapping_players.size() > 0


func _on_body_entered(body: Node2D) -> void:
	if body is Player and !overlapping_players.has(body):
		overlapping_players.append(body)
		player_entered.emit()

func _on_body_exited(body: Node2D) -> void:
	if body is Player and overlapping_players.has(body):
		overlapping_players.erase(body)
		player_exited.emit()
