@tool
extends Item


@export var rekt_sprite: Texture2D = null
@export var impact_sfx: StringName = &"rekt_sign"


func _ready() -> void:
	%hitbox.hit.connect(_on_hitbox_hit)


func get_activated():
	super()
	smack()

func smack():
	if is_instance_valid(holder):
		$hitbox.add_exception(holder.get_hurtbox())
		# Use this connection to remove the above collision exception
		$animator.animation_finished.connect(_on_animation_finished)
		
		$animator.play("smack")
		holder.animation_lock( $animator.get_animation(&"smack").length - 0.5 )

func activate_hitbox():
	%hitbox.active = true
	var timer := get_tree().create_timer(.1)
	timer.timeout.connect(func():
		%hitbox.active = false
	)
	
	GlobalSound.play_sfx_2d(impact_sfx, global_position)
	$camera_shaker.activate()

func _on_animation_finished(anim_name):
	if anim_name == "smack":
		# Remove the holder from exceptions after the animation is done
		if holder:
			$hitbox.remove_exception(holder.get_hurtbox())
		# Disconnect signals to avoid redundant calls
		$animator.animation_finished.disconnect(_on_animation_finished)

func _on_hitbox_hit():
	var new_sprite: TransientSprite2D = TransientSprite2D.new()
	new_sprite.texture = rekt_sprite
	new_sprite.hframes = 8
	Game.deploy_instance(new_sprite, %rektsplosion_spawn.global_position)
	new_sprite.scale = %rektsplosion_spawn.scale
