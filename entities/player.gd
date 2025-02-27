@icon("res://entities/player.png")
class_name Player
extends Entity

# MOVEMENT SETTINGS
@export_group("Movement")
@export var gravity_fast_fall_mult := 4.0
@export var move_speed := 350.0
@export var max_speed := 400.0
@export var jump_speed_boost := 0.5
@export var air_jumps := 1
@export var jump_speed := 1500.0
@export var drop_speed := 300.0
@export var controller := 0  # Default: 0 for Player 1, 1 for Player 2, etc.

# INTERACTION SETTINGS
@export_group("Interaction")
@export var grab_range := 64.0
@export var throw_speed := 2000.0

# RESOURCE SETTINGS
@export_group("Resources")
@export var death_sfx: StringName = "death"
@export var hit_sfx: StringName = "player_hit"
@export var jump_sfx: StringName = "player_jump"
@export var jump_particles: PackedScene = preload("res://fx/jump.tscn")

# MULTIPLAYER & PHYSICS STATE
@export var multiplayer_owner: int = 1
var traction: float = 0
var floating: bool = false
var current_air_jumps: int = air_jumps
var has_dropped: bool = false
var held_item: Item = null
var sound_player: AudioStreamPlayer = null
var has_died: bool = false
# Input state variables - moved from player_normal.gd to player instance
var left_pressed: bool = false
var right_pressed: bool = false

# NEW: Track time since (re)spawn locally (in seconds).
var time_since_spawn: float = 0.0

func _init() -> void:
	super()
	add_to_group("players")

func _ready() -> void:
	super()
	hp_changed.connect(PlayerManager._on_player_hp_changed.bind(get_id()))
	set_multiplayer_authority(1)

	if Game.is_multiplayer:
		%number.hide()
	else:
		%number.text = "P%s" % (controller + 1)

# Instead of _process, you may have _physics_process depending on your setup.
# We'll assume _process is enough here. If you are using _physics_process, move this increment there.
func _process(delta: float) -> void:
	# Increment time_since_spawn each frame.
	time_since_spawn += delta

	# Only run physics-like code if single-player or if this instance is the server authority.
	if not Game.is_multiplayer or is_multiplayer_authority():
		super(delta)
		accelerate(traction, delta)
		if is_on_floor():
			current_air_jumps = air_jumps
			has_dropped = false

	# Debug: allow Player 0 to die manually.
	if controller == 0 and Input.is_action_just_pressed("debug_die"):
		die()

func get_hand_position() -> Vector2:
	return %hand.global_position

# Resets movement and re-initializes time_since_spawn = 0.
func reset_movement() -> void:
	velocity = Vector2.ZERO
	traction = 0
	floating = false
	has_dropped = false
	current_air_jumps = air_jumps
	# Reset input state when respawning
	left_pressed = false
	right_pressed = false
	time_since_spawn = 0.0

func get_id() -> int:
	if Game.is_multiplayer:
		return PlayerManager.get_player_index(self)
	else:
		return controller

func is_owner() -> bool:
	if not Game.is_multiplayer:
		return true
	return multiplayer_owner == multiplayer.get_unique_id()

# MOVEMENT METHODS

@rpc("any_peer", "call_remote", "reliable")
func attempt_jump():
	if is_on_floor():
		rpc_jump_succeed.rpc()
	else:
		if current_air_jumps > 0 and velocity.y > -jump_speed:
			current_air_jumps -= 1
			rpc_jump_succeed.rpc()

@rpc("authority", "call_local", "reliable")
func rpc_jump_succeed():
	velocity.y = -jump_speed
	velocity.x *= (jump_speed_boost + 1)
	if jump_particles:
		var new_particles = jump_particles.instantiate()
		Game.deploy_instance(new_particles, global_position)
	if jump_sfx:
		GlobalSound.play_sfx_2d(jump_sfx, global_position)

@rpc("any_peer", "call_remote", "reliable")
func rpc_tractutate(new_traction: float):
	traction = new_traction

func frictutate(delta: float):
	var _friction: float = 1.0 / delta
	if max_speed > 0:
		_friction = acceleration / max_speed
	velocity.x -= velocity.x * _friction * delta

func gravitate(delta: float):
	super(delta)
	if not floating:
		velocity.y += gravity * delta * gravity_fast_fall_mult - 1

@rpc("any_peer", "call_remote", "reliable")
func attempt_drop():
	if is_on_floor() or not has_dropped:
		rpc_drop.rpc()
		has_dropped = true

@rpc("authority", "call_local", "reliable")
func rpc_drop():
	position.y += 1
	velocity.y = max(drop_speed, velocity.y + drop_speed)

@rpc("any_peer", "call_remote", "reliable")
func rpc_set_floating(what: bool):
	floating = what

# ITEM MANAGEMENT

@rpc("any_peer", "call_remote", "reliable")
func attempt_grab():
	if is_instance_valid(held_item):
		throw_item.rpc()
	else:
		grab_nearest_item()

@rpc("any_peer", "call_local", "reliable")
func throw_item():
	if is_instance_valid(held_item):
		held_item.get_thrown()
		held_item.set_holder(null)
		held_item.apply_central_impulse(Vector2(throw_speed, 0) * $flippable.scale)
		held_item = null

func grab_nearest_item() -> bool:
	var hand_position = get_hand_position()
	var target_item: Item = Util.get_nearest_group_member("items", hand_position)
	if not is_instance_valid(target_item):
		return false
	if not target_item.grabable:
		return false
	if is_instance_valid(target_item.holder):
		return false
	if hand_position.distance_squared_to(target_item.global_position) > grab_range * grab_range:
		return false
	rpc_grab_item_by_path.rpc(get_path_to(target_item))
	return true

@rpc("authority", "call_local", "reliable")
func rpc_grab_item_by_path(item_path: NodePath):
	var target_item: Item = get_node(item_path)
	if is_instance_valid(target_item):
		target_item.set_holder(self)
		held_item = target_item

@rpc("any_peer", "call_remote", "reliable")
func activate_item():
	if is_instance_valid(held_item) and held_item.enabled:
		rpc_activate_item.rpc(held_item.global_position, held_item.global_rotation)

@rpc("authority", "call_local", "reliable")
func rpc_activate_item(pos: Vector2, rot: float):
	if is_instance_valid(held_item) and held_item.enabled:
		held_item.global_position = pos
		held_item.global_rotation = rot
		held_item.get_activated()

func spawn_item(item: PackedScene, auto_grab: bool = true):
	if multiplayer.is_server():
		var new_item: Item = Game.create_instance(item)
		Game.deploy_instance(new_item, global_position)
		if auto_grab and not is_instance_valid(held_item):
			rpc_grab_item_by_path.rpc(get_path_to(new_item))

# OTHER GAME METHODS

func get_hurtbox() -> Hurtbox:
	return $hurtbox

func set_state(what: String):
	$fsm.set_state(what)

func animation_lock(duration: float = 1):
	traction = 0
	%animation_lock.duration = duration
	set_state("animation_lock")

func take_damage(what: float, can_heal: bool = true):
	super(what, can_heal)
	if what > 0:
		$animator.play("hit_flash")
		GlobalSound.play_sfx_2d(hit_sfx, global_position)

func die() -> void:
	if has_died:
		return
	has_died = true
	if not is_inside_tree():
		return
	var peers = MattohaSystem.Client.GetLobbyPlayersIds()
	for peer_id in peers:
		rpc_id(peer_id, "emit_die_signal_rpc")
	super()
	GlobalSound.play_sfx_2d(death_sfx, global_position)

@rpc("any_peer", "call_local", "reliable")
func emit_die_signal_rpc():
	Events.player_died.emit(get_id())

# WEARABLE MANAGEMENT

func add_wearable(what: Wearable) -> void:
	var wearables_node: Node2D
	if not has_node("wearables"):
		wearables_node = Node2D.new()
		wearables_node.name = "wearables"
		add_child(wearables_node)
	else:
		wearables_node = get_node("wearables")
	var new_sprite: Sprite2D = Sprite2D.new()
	new_sprite.texture = what.sprite
	new_sprite.position = what.offset
	wearables_node.add_child(new_sprite)

# OTHER INTERACTION CALLBACKS

func _on_item_pickup(item):
	if item is RigidBody2D and item.name == "sushi_knife":
		item.set_knife_owner(self)
		print("Player: Picked up sushi knife ", item.name)
