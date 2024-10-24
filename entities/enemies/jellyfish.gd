extends Enemy


@export var bullet_scene: PackedScene = null


func shoot():
	%flash_animator.play("flash")
	for i in range(3):
		var new_bullet: Projectile = Game.create_instance(bullet_scene) as Projectile
		Game.deploy_instance(new_bullet, %barrel.global_position)
		new_bullet.velocity = Vector2(50 + 75*i, 0)
		new_bullet.velocity.x *= 1 if %flippable.scale.x > 0 else -1
		new_bullet.duration = 5 + 2*i


func _on_player_detector_player_within():
	%idle.set_state("shoot")
