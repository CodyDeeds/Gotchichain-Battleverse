extends HBoxContainer
class_name LivesList

@export var life_icon: PackedScene
@export var player: int = 0


func _ready() -> void:
	PlayerManager.player_stats_updated.connect(update_lives)
	update_lives()


func update_lives():
	clear_lives()
	if PlayerManager.players.size() > player:
		add_lives( PlayerManager.players[player].lives )

func clear_lives():
	for i in get_children():
		i.queue_free()

func add_lives(lives: Array):
	for i in lives.size():
		var new_icon = life_icon.instantiate()
		add_child(new_icon)
