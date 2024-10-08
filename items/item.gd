@tool
@icon("res://items/item.png")
class_name Item
extends RigidBody2D

## Speed above which this item will bonk players hit by it
@export var bonk_speed_threshhold := 1000.0
## Damage dealt to players at which this item is thrown
@export var bonk_damage := 0.0
## Closeness with which this item follows its holder
@export var follow_speed := 20.0
## Speed with which this item straightens itself when held
@export var straighten_speed := 100.0
## Size of the item's hitbox
@export var hitbox_size := 32.0: set = set_hitbox_size
## How scaled up will the sprite be?
@export var sprite_scale := 1.0
## Whether the sprite flips vertically when facing left
@export var flip_sprite := true
## Whether or not this item can be grabbed
@export var grabable := true
## The player that will automatically grab this item
@export var auto_grab: NodePath = ""

@export_group("Config")
@export var id: String = ""

@export_group("Resources")
## SFX to play when this item is activated
@export var activation_sfx: StringName = &""
## SFX to play when this item is destroyed
@export var destruction_sfx: StringName = &""
## SFX to play when this item is grabbed
@export var grab_sfx: StringName = &""
## SFX to play when this item is thrown
@export var throw_sfx: StringName = &""
## SFX to play when this item is thrown 1% of the time
@export var rare_throw_sfx: StringName = &""

var holder: Player = null
var previous_holder: Player = null
var can_hit_previous_holder: bool = false

func _init() -> void:
	add_to_group("items")
	if id == "":
		id = name

func _ready() -> void:
	if !Engine.is_editor_hint():
		set_hitbox_size(hitbox_size)
		PhysicsServer2D.body_set_continuous_collision_detection_mode(get_rid(), PhysicsServer2D.CCD_MODE_CAST_RAY)
		
		if has_node(auto_grab):
			var player: Player = get_node(auto_grab)
			player.held_item = self
			holder = player
	
	tree_exiting.connect(_on_slain)

func _process(delta: float) -> void:
	%sprite.scale = Vector2(sprite_scale, sprite_scale)
	
	if !Engine.is_editor_hint():
		follow_holder(delta)
		attempt_bonk()
		
		if is_instance_valid(holder):
			flip_with_holder()
			if straighten_speed != 0:
				straighten(delta)
		else:
			if freeze:
				freeze = false
				set_holder(null)


func get_id() -> String:
	if id == "":
		return name
	else:
		return id

func flip_with_holder():
	var hand_relative_pos: float = (holder.get_hand_position() - holder.global_position).x
	if hand_relative_pos < 0 and flip_sprite:
		%flip.scale.y = -1
	if hand_relative_pos > 0 or !flip_sprite:
		%flip.scale.y = 1

func straighten(delta):
	var dir_vector := Vector2()
	dir_vector.x = holder.get_hand_position().x - holder.global_position.x
	dir_vector.y = global_position.y - holder.get_hand_position().y
	dir_vector = dir_vector.normalized()
	var dir: float = dir_vector.angle()
	var difference = angle_difference(global_rotation, dir)
	
	rotation += difference * straighten_speed * delta
	#angular_velocity = difference * straighten_speed

func follow_holder(delta: float):
	if is_instance_valid(holder):
		var difference: Vector2 = holder.get_hand_position() - global_position
		var direction: Vector2 = difference.normalized()
		var distance: float = difference.length()

		position += direction * distance * follow_speed * delta
		#apply_central_impulse(direction * distance * follow_speed)

func attempt_bonk():
	# If moving fast enough
	if !is_instance_valid(holder) and linear_velocity.length_squared() > bonk_speed_threshhold * bonk_speed_threshhold:
		var players: Array[Player] = %player_detector.overlapping_players
		for this_player in players:
			# Don't hit the player that just threw this item
			if can_hit_previous_holder or this_player != previous_holder:
				# If moving toward the player in question
				var player_dir: Vector2 = (this_player.global_position - global_position).normalized()
				var projected_speed = linear_velocity.dot(player_dir)
				if projected_speed > 0:
					var upwardyness := Vector2(0, -400)
					var impact_vector: Vector2 = player_dir * projected_speed
					this_player.take_knockback(impact_vector + upwardyness)
					this_player.take_damage(bonk_damage)
					apply_central_impulse( - impact_vector * 2 + upwardyness)
					can_hit_previous_holder = true

func get_activated():
	#Game.print_multiplayer("Item %s activated" % name)
	GlobalSound.play_sfx_2d(activation_sfx, global_position)

func get_thrown():
	if randf() * 100 < 1:
		GlobalSound.play_sfx_2d(rare_throw_sfx, global_position)
	else:
		GlobalSound.play_sfx_2d(throw_sfx, global_position)

func set_holder(what: Player):
	var peers = MattohaSystem.Client.GetLobbyPlayersIds()
	var node_path = ""
	if (what != null):
		node_path = what.get_path()
	for peer_id in peers:
		rpc_id(peer_id, "rpc_set_holder", node_path)

@rpc("any_peer", "call_local", "reliable")
func rpc_set_holder(node_path):
	#Game.print_multiplayer("Item: rpc_set_holder called with node path %s " % node_path)
	var what: Player = null
	if (get_tree().root.has_node(node_path)):
		what = get_node(node_path)
		set_multiplayer_authority(what.get_multiplayer_authority())
	
	if holder and !is_instance_valid(what):
		previous_holder = holder
		can_hit_previous_holder = false
	
	if is_instance_valid(what) and holder != what:
		GlobalSound.play_sfx_2d(grab_sfx, global_position)
	
	holder = what
	
	freeze = is_instance_valid(holder)
	%damper.active = is_instance_valid(holder)
	#if is_instance_valid(holder):
		#print("Item: Set holder to ", holder.name)
	#else:
		#print("Item: Set holder to null")

func set_texture(what: Texture):
	%sprite.texture = what

func set_bonk_damage(what: float):
	bonk_damage = what

func set_hitbox_size(what: float):
	hitbox_size = what

	if is_inside_tree():
		var polygon = PackedVector2Array()
		for i in range(8):
			var angle = PI / 8 + PI / 4 * i
			var point = Vector2(what, 0).rotated(angle)
			polygon.append(point)
		%shape.polygon = polygon

func set_sprite_scale(what: float):
	sprite_scale = what

# Ensure to call this function when the knife is picked up
func _on_player_pickup(player):
	set_holder(player)

func _on_slain():
	GlobalSound.play_sfx_2d(destruction_sfx, global_position)
