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

@export_group("Resources")
@export var death_sfx: StringName = &"death"
@export var hit_sfx: StringName = &"player_hit"
@export var jump_sfx: StringName = &"player_jump"
@export var jump_particles: PackedScene = preload("res://fx/jump.tscn")

## The session ID that controls this player (different from the multiplayer authority)
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
	
	# Connect HP changes (using get_id() to obtain this player's identifier)
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
		if is_on_floor():
			current_air_jumps = air_jumps
			has_dropped = false

	# Debug command to die for Player One
	if controller == 0 and Input.is_action_just_pressed("debug_die"):
		die()

func get_hand_position() -> Vector2:
	return %hand.global_position

## NEW: Reset all movement-related state variables. Call this upon spawn.
func reset_movement() -> void:
	velocity = Vector2.ZERO
	traction = 0
	floating = false
	has_dropped = false
	current_air_jumps = air_jumps

## NEW: Added get_id() so that the player instance can report its ID.
func get_id() -> int:
	if Game.is_multiplayer:
		return PlayerManager.get_player_index(self)
	else:
		return controller

# (Rest of your player.gd functionality remains unchanged)
