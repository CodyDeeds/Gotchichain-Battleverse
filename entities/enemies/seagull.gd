extends Enemy


## How long this seagull flies before spontaneously expiring
@export var duration := 12.0
## How often does this seagull drop bombs
@export var bomb_interval := 2.0

var source: Node = null

const bomb_scene = preload("res://projectiles/seagull_bomb.tscn")
const feathers_scene = preload("res://fx/seagull_feathers.tscn")


func _ready() -> void:
	super()
	
	%timer.start(randf() * bomb_interval)
	%timer.wait_time = bomb_interval
	velocity = Vector2(-300, randf_range(-50, 50))
	
	render_intangible_to_players()
	PlayerManager.player_spawned.connect(render_intangible_to_players)

func _physics_process(delta: float) -> void:
	super(delta)
	
	for i in range( get_slide_collision_count() ):
		var this_collision := get_slide_collision(i)
		var collider := this_collision.get_collider()
		
		if !is_instance_valid(collider):
			continue
		if !(collider is CollisionObject2D or collider is TileMap):
			continue
		if !collider.get_collision_layer_value(3):
			continue
		
		expire()


func render_intangible_to_players():
	for this_player in get_tree().get_nodes_in_group(&"players"):
		add_collision_exception_with(this_player)
		this_player.add_collision_exception_with(self)

func drop_bomb():
	var new_bomb = Game.create_instance(bomb_scene)
	new_bomb.add_exception(%hurtbox)
	Game.deploy_instance(new_bomb, global_position)

func deploy_feathers():
	var new_feathers = feathers_scene.instantiate()
	Game.deploy_instance(new_feathers, global_position)

func expire():
	if is_instance_valid(source):
		source.value += value
	deploy_feathers()
	queue_free()

func die():
	super()
	deploy_feathers()


func _on_timer_timeout() -> void:
	drop_bomb()
