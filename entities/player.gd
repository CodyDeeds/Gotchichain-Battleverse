@icon("res://entities/player.png")
class_name Player
extends Entity

@export_group("Movement")
## When the jump button is not held, gravity will be multiplied by this number
@export var gravity_fast_fall_mult := 4.0
@export var move_speed := 350.0
@export var max_speed := 400.0
## When jumping, horizontal speed is increased by this amount multiplicatively
@export var jump_speed_boost := 0.5
@export var air_jumps := 1
@export var jump_speed := 1500.0
## Speed with which the player drops through platforms
@export var drop_speed := 300.0
@export var controller := 0  # Default to 0 for Player 1, change to 1 for Player 2, etc.
@export_group("Interaction")
@export var grab_range := 64.0
@export var throw_speed := 2000.0

# Preload the death sound effect
@export_group("Resources")
@export var death_sfx: StringName = &"death"
@export var hit_sfx: StringName = &"player_hit"
@export var jump_sfx: StringName = &"player_jump"
@export var jump_particles: PackedScene = preload("res://fx/jump.tscn")

## The session ID that controls this player, one of the clients. Different from the multiplayer authority, as that is always the server
@export var multiplayer_owner: int = 1
## Speed with which this player is intentionally moving
var traction: float = 0
## Whether the player is slow-falling or fast-falling
var floating: bool = false
var current_air_jumps: int = air_jumps
## Whether the player has dropped to increase speed while falling
var has_dropped: bool = false
var held_item: Item = null
var sound_player: AudioStreamPlayer = null
var has_died: bool = false

func _init() -> void:
	super()
	add_to_group(&"players")

func _ready() -> void:
	super()
	
	hp_changed.connect(PlayerManager._on_player_hp_changed.bind(get_id()))
	
	set_multiplayer_authority(1)
	
	if Game.is_multiplayer:
		%number.hide()
	else:
		%number.text = "P%s" % (controller + 1)

func _process(delta: float) -> void:
	# Physics-y simulation aspects on server only
	if !Game.is_multiplayer or is_multiplayer_authority():
		super(delta)
		accelerate(traction, delta)
		#move_and_slide()
		if is_on_floor():
			current_air_jumps = air_jumps
			has_dropped = false

	# Debug command to die for Player One
	if controller == 0 and Input.is_action_just_pressed("debug_die"):
		die()

func get_hand_position() -> Vector2:
	return %hand.global_position

# ######## ######## ######## ######## MOVEMENT ######## ######## ########

## Checks to see if it can jump, and does so if possible
## Meant to run on the server only, calling [code]rpc_jump_succeed[/code] on all clients if the jump is successful
@rpc("any_peer", "call_remote", "reliable")
func attempt_jump():
	if is_on_floor():
		rpc_jump_succeed.rpc()
	else:
		if current_air_jumps > 0 and velocity.y > -jump_speed:
			current_air_jumps -= 1
			rpc_jump_succeed.rpc()

## Jumps unconditionally without checks for if it's on the ground or not
@rpc("authority", "call_local", "reliable")
func rpc_jump_succeed():
	velocity.y = -jump_speed
	velocity.x *= (jump_speed_boost + 1)
	if jump_particles:
		var new_particles = jump_particles.instantiate()
		Game.deploy_instance(new_particles, global_position)
	if jump_sfx:
		GlobalSound.play_sfx_2d(jump_sfx, global_position)

@rpc("any_peer", "call_remote", "unreliable")
func rpc_tractutate(new_traction: float):
	traction = new_traction

func frictutate(delta: float):
	var _friction: float = 1.0 / delta
	if max_speed > 0:
		_friction = acceleration / max_speed
	velocity.x -= velocity.x * _friction * delta

func gravitate(delta: float):
	super(delta)
	if !floating:
		velocity.y += gravity * delta * (gravity_fast_fall_mult) - 1

## Checks to see if it can drop through a platform, and does so if possible
@rpc("any_peer", "call_remote", "reliable")
func attempt_drop():
	if is_on_floor() or !has_dropped:
		rpc_drop.rpc()
		has_dropped = true

@rpc("authority", "call_local", "reliable")
func rpc_drop():
	position.y += 1
	velocity.y = max(drop_speed, velocity.y + drop_speed)

@rpc("any_peer", "call_remote", "reliable")
func rpc_set_floating(what: bool):
	floating = what

# ######## ######## ######## ######## ITEM MANAGEMENT ######## ######## ######## ########

## Run on server only, checks to see if a valid item is nearby and grabs it if so
@rpc("any_peer", "call_remote", "reliable")
func attempt_grab():
	#Game.print_multiplayer("Attempting to grab item")
	if is_instance_valid(held_item):
		#Game.print_multiplayer("Cannot grab; item in hand")
		throw_item.rpc()
	else:
		#Game.print_multiplayer("No item in hand")
		grab_nearest_item()

@rpc("any_peer", "call_local", "reliable")
func throw_item():
	#Game.print_multiplayer("Player: Threw item %s" % held_item.name)
	held_item.get_thrown()
	held_item.set_holder(null)
	held_item.apply_central_impulse(Vector2(throw_speed, 0) * $flippable.scale)
	held_item = null

## Also checks if there is a valid nearest item. if not, grabs nothing and returns false
func grab_nearest_item() -> bool:
	var hand_position := get_hand_position()
	var target_item: Item = Util.get_nearest_group_member("items", hand_position)
	
	if !is_instance_valid(target_item):
		#Game.print_multiplayer("Cannot grab, no target item")
		return false
	if !target_item.grabable:
		#Game.print_multiplayer("Cannot grab, nearest item is not grabable")
		return false
	if is_instance_valid(target_item.holder):
		return false
	if hand_position.distance_squared_to(target_item.global_position) > grab_range * grab_range:
		#Game.print_multiplayer("Cannot grab, nearest item is too distant")
		return false
	
	#Game.print_multiplayer("Grabbed item %s successfully" % [target_item.name])
	rpc_grab_item_by_path.rpc( get_path_to(target_item) )
	return true

@rpc("authority", "call_local", "reliable")
func rpc_grab_item_by_path(item_path: NodePath):
	#Game.print_multiplayer("Player grabs item %s" % item_path)
	var target_item: Item = get_node(item_path)
	target_item.set_holder(self)
	held_item = target_item

## Run on server only
@rpc("any_peer", "call_remote", "reliable")
func activate_item():
	if is_instance_valid(held_item):
		rpc_activate_item.rpc(held_item.global_position, held_item.global_rotation)

## This function assumes there is a valid held item
@rpc("authority", "call_local", "reliable")
func rpc_activate_item(pos: Vector2, rot: float):
	# Position and rotation are that of the held item
	# They are sent in order to ensure consistent placement of the item before activation
	if is_instance_valid(held_item):
		held_item.global_position = pos
		held_item.global_rotation = rot
		held_item.get_activated()

func spawn_item(item: PackedScene, auto_grab: bool = true):
	#Game.print_multiplayer("Player spawns item from %s" % item.resource_path)
	if multiplayer.is_server():
		var new_item: Item = Game.create_instance(item)
		Game.deploy_instance(new_item, global_position)
		#new_item.auto_grab = new_item.get_path_to(self)
		
		if auto_grab and !is_instance_valid(held_item):
			#Game.print_multiplayer("Player successfully spawns item, and grabs item at %s" % get_path_to(new_item))
			rpc_grab_item_by_path.rpc( get_path_to(new_item) )

# ######## ######## ######## ########  ######## ######## ######## ########

func get_hurtbox() -> Hurtbox:
	return $hurtbox

func set_state(what: String):
	$fsm.set_state(what)

func animation_lock(duration: float = 1):
	traction = 0
	%animation_lock.duration = duration
	set_state("animation_lock")

func take_damage(what: float, can_heal: bool=true):
	super(what, can_heal)
	if what > 0:
		$animator.play("hit_flash")
		GlobalSound.play_sfx_2d(hit_sfx, global_position)
		#print("Player: Took damage ", what)

func die() -> void:
	if has_died:
		return
	has_died = true
	
	if !is_inside_tree():
		return
	
	var peers = MattohaSystem.Client.GetLobbyPlayersIds()
	for peer_id in peers:
		rpc_id(peer_id, "emit_die_signal_rpc")
	super()
	
	GlobalSound.play_sfx_2d(&"death", global_position)
	#print("Player: Died")

@rpc("any_peer", "call_local", "reliable")
func emit_die_signal_rpc():
	Events.player_died.emit(get_id())

func is_owner():
	#Game.print_multiplayer("Player %s has owner %s" % [get_path(), multiplayer_owner])
	if !Game.is_multiplayer:
		return true
	return multiplayer_owner == multiplayer.get_unique_id()

## Returns this player's position in the PlayerManager.players array
func get_id() -> int:
	if Game.is_multiplayer:
		return PlayerManager.get_player_index(self)
	else:
		return controller

func add_wearable(what: Wearable):
	var new_sprite := Sprite2D.new()
	new_sprite.texture = what.sprite
	new_sprite.position = what.offset
	%wearables.add_child(new_sprite)


# Ensure to call this function when the player picks up an item
func _on_item_pickup(item):
	if item is RigidBody2D and item.name == "sushi_knife":
		item.set_knife_owner(self)
		print("Player: Picked up sushi knife ", item.name)
