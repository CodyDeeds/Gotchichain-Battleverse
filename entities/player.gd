@icon("res://entities/player.png")
class_name Player
extends Entity

@export_group("Movement")
@export var gravity := 500.0
## When the jump button is not held, gravity will be multiplied by this number
@export var gravity_fast_fall_mult := 4.0
@export var move_speed := 350.0
@export var max_speed := 400.0
## When jumping, horizontal speed is increased by this amount multiplicatively
@export var jump_speed_boost := 0.5
@export var acceleration := 2000.0
@export var air_jumps := 1
@export var jump_speed := 1500.0
@export var controller := 0
@export_group("Interaction")
@export var grab_range := 64.0
@export var throw_speed := 2000.0

# Preload the death sound effect
@export_group("Resources")
@export var death_sound: AudioStream = preload("res://audio/sfx/death.ogg")
@export var jump_particles: PackedScene = preload("res://fx/jump.tscn")

var current_air_jumps: int = air_jumps
var held_item: Item = null
var sound_player: AudioStreamPlayer = null
var has_died: bool = false

func _init() -> void:
	add_to_group("players")

func _ready() -> void:
	# Initialize and configure the sound player
	sound_player = AudioStreamPlayer.new()
	add_child(sound_player)
	sound_player.stream = death_sound
	sound_player.volume_db = -10  # Set volume to -10 dB for testing
	sound_player.autoplay = false  # Ensure autoplay is off
	sound_player.bus = "Master"  # Ensure it's on the correct audio bus
	#print("Player: Sound player initialized with volume: ", sound_player.volume_db)

func _process(delta: float) -> void:
	if !is_owner():
		return
	
	# for desktop control
	var x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	if x != 0:
		velocity.x = x * move_speed
	gravitate(delta)
	frictutate(delta)
	move_and_slide()
	if is_on_floor():
		current_air_jumps = air_jumps


func get_hand_position() -> Vector2:
	return %hand.global_position

# ######## ######## ######## ######## MOVEMENT ######## ######## ######## ########

func jump():
	var succeed: Callable = func():
		velocity.y = -jump_speed
		velocity.x *= (jump_speed_boost + 1)
		var new_particles = MattohaSystem.CreateInstance(jump_particles.resource_path)
		new_particles.position = global_position
		MattohaSystem.GetLobbyNodeFor(self).add_child(new_particles)
	
	if is_on_floor():
		succeed.call()
	else:
		if current_air_jumps > 0 and velocity.y > -jump_speed:
			current_air_jumps -= 1
			succeed.call()

func frictutate(delta: float):
	var friction: float = 1.0 / delta
	if max_speed > 0:
		friction = acceleration / max_speed
	velocity.x -= velocity.x * friction * delta

func accelerate(dir: float, delta: float):
	velocity.x += acceleration * dir * delta

func gravitate(delta: float):
	velocity.y += gravity * delta
	if is_owner():
		if !Input.is_joy_button_pressed(controller, JOY_BUTTON_A):
			velocity.y += gravity * delta * (gravity_fast_fall_mult) - 1

# ######## ######## ######## ######## ITEM MANAGEMENT ######## ######## ######## ########

func attempt_grab():
	if is_instance_valid(held_item):
		rpc("throw_item")
	else:
		grab_nearest_item()

@rpc("any_peer", "call_local", "reliable")
func throw_item():
	print("Player: Threw item ", held_item.name)
	held_item.get_thrown()
	held_item.set_holder(null)
	held_item.apply_central_impulse(Vector2(throw_speed, 0) * $flippable.scale)
	held_item = null

func grab_nearest_item():
	var hand_position := get_hand_position()
	var target_item: Item = Util.get_nearest_group_member("items", hand_position)
	grab_item_by_path.rpc( get_path_to(target_item) )

@rpc("any_peer", "call_local", "reliable")
func grab_item_by_path(item_path: NodePath):
	Game.print_multiplayer("Player grabs item %s" % item_path)
	var hand_position := get_hand_position()
	var target_item: Item = get_node(item_path)
	if is_instance_valid(target_item) and target_item.grabable:
		if hand_position.distance_squared_to(target_item.global_position) < grab_range * grab_range:
			target_item.set_holder(self)
			held_item = target_item

func activate_item():
	if is_instance_valid(held_item):
		rpc("rpc_activate_item", held_item.global_position, held_item.global_rotation)

@rpc("any_peer", "call_local", "reliable")
func rpc_activate_item(pos: Vector2, rot: float):
	if is_instance_valid(held_item):
		held_item.global_position = pos
		held_item.global_rotation = rot
		held_item.get_activated()

func spawn_item(res_path: String, auto_grab: bool = true):
	print(res_path)
	for i in get_children():
		print(i.name)
	
	Game.print_multiplayer("Player spawns item from %s" % res_path)
	if multiplayer.is_server():
		var new_item: Item = MattohaSystem.CreateInstance(res_path)
		new_item.global_position = global_position
		MattohaSystem.GetLobbyNodeFor(self).add_child(new_item)
		#new_item.auto_grab = new_item.get_path_to(self)
		
		if auto_grab and !is_instance_valid(held_item):
			Game.print_multiplayer("Player successfully spawns item, and grabs item at %s" % get_path_to(new_item))
			grab_item_by_path.rpc( get_path_to(new_item) )

# ######## ######## ######## ########  ######## ######## ######## ########

func get_hurtbox() -> Hurtbox:
	return $hurtbox

func take_damage(what: float, can_heal: bool=true):
	super(what, can_heal)
	if what > 0:
		$animator.play("hit_flash")
		print("Player: Took damage ", what)

func die() -> void:
	if has_died:
		return
	has_died = true

	# Play the death sound and wait for it to finish before removing the player
	if sound_player and death_sound:
		sound_player.stop()  # Ensure any previous sound is stopped
		sound_player.volume_db = -10  # Ensure volume is set to an audible level
		sound_player.play()
		print("Player: Death sound played with volume: ", sound_player.volume_db)
		await get_tree().create_timer(death_sound.get_length()).timeout
	else:
		print("Player: Death sound or sound player not initialized correctly")

	var peers = MattohaSystem.Client.GetLobbyPlayersIds()
	for peer_id in peers:
		rpc_id(peer_id, "emit_die_signal_rpc")
	super()
	print("Player: Died")

@rpc("any_peer", "call_local", "reliable")
func emit_die_signal_rpc():
	Events.player_died.emit(get_multiplayer_authority())

func is_owner():
	return multiplayer.get_unique_id() == get_multiplayer_authority()

# Ensure to call this function when the player picks up an item
func _on_item_pickup(item):
	if item is RigidBody2D and item.name == "sushi_knife":
		item.set_knife_owner(self)
		print("Player: Picked up sushi knife ", item.name)
