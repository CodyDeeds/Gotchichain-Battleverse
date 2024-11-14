extends Item


## Number of airstrikes launched
@export var airstrike_count := 5
## Delay before the first airstrike lands
@export var initial_delay := 2.0
## Amount of time between one airstrike landing and the next
@export var delay_interval := 0.1
## Distance from item to first airstrike
@export var initial_distance := 256.0
## Distance from one airstrike to the next
@export var distance_interval := 128.0
## Damage dealt by bombs
@export var damage := 3
## Item cannot be reused for this long after activation
@export var disable_duration := 5.0

const airstrike_scene = preload("res://fx/airstrike.tscn")


func _ready() -> void:
	super()
	%disable_timer.wait_time = disable_duration


func get_activated():
	super()
	deploy_airstrikes()
	enabled = false
	update_sprite_frame()
	%disable_timer.start()

func deploy_airstrikes():
	for i in range(airstrike_count):
		var new_strike = Game.create_instance( airstrike_scene )
		new_strike.damage = damage
		new_strike.duration = initial_delay + delay_interval*i
		var pos := global_position
		pos.y -= new_strike.get_max_floor_distance() / 2
		var xpos := initial_distance + distance_interval*i
		pos.x += xpos if %flip.scale.y > 0 else -xpos
		Game.deploy_instance(new_strike, pos)

@rpc("any_peer", "call_local", "reliable")
func rpc_set_holder(node_path):
	super(node_path)
	update_sprite_frame()

func update_sprite_frame():
	%sprite.frame = 1
	if !is_instance_valid(holder) or enabled:
		%sprite.frame = 0


func _on_disable_timer_timeout() -> void:
	enabled = true
	update_sprite_frame()
