extends VBoxContainer
class_name LivesList

@export var life_icon: PackedScene
@export var health_icon: PackedScene
@export var flipped: bool = false
@export var player: int = 0

var hearts: Array = []


func _ready() -> void:
	PlayerManager.player_stats_updated.connect(update_lives)
	PlayerManager.player_stats_updated.connect(update_health)
	
	if flipped:
		move_child(%health, 0)


func update_lives():
	clear_lives()
	if PlayerManager.players.size() > player:
		add_lives( PlayerManager.players[player].lives )

func clear_lives():
	for i in %lives.get_children():
		i.queue_free()

func add_lives(lives: Array):
	for i in lives.size():
		var new_icon = life_icon.instantiate()
		%lives.add_child(new_icon)

func update_health():
	if PlayerManager.players.size() > player:
		add_health( PlayerManager.players[player].health, PlayerManager.players[player].max_health )

func clear_health():
	for i in %health.get_children():
		i.queue_free()
	hearts = []

func add_health(health: Array, max_health: int):
	for i in range(max_health):
		var this_icon
		
		# Create new heart icons where necessary
		if i >= hearts.size():
			var new_icon = health_icon.instantiate()
			%health.add_child(new_icon)
			
			var advancement: float = 10 - i * 0.2
			new_icon.advance_animation(advancement)
			hearts.append(new_icon)
		
		# Set the visual traits of the heart correctly
		this_icon = hearts[i]
		if i >= health.size():
			this_icon.type = -1
		else:
			this_icon.type = 0
