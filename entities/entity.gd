class_name Entity
extends CharacterBody2D

var max_hp := 5.0
var hp := max_hp
var limit_hp := true
var dead := false


signal hp_changed(new_hp: float)


func _ready() -> void:
	pass


func set_hp(what: float):
	hp = what

	if hp <= 0&&!dead:
		die()

	if limit_hp:
		hp = min(hp, max_hp)
	
	# Using an array here rather than the actual value in case of multiple types of hearts that need keeping track of a la Isaac
	# Not changing the regular HP variable to an array yet because that hasn't been made yet and might not be for a while
	hp_changed.emit( get_health_array() )

func take_damage(what: float, can_heal: bool=true):
	if !can_heal:
		what = max(what, 0)

	set_hp(hp - what)

func die():
	if !is_inside_tree():
		return
	var peers = MattohaSystem.Client.GetLobbyPlayersIds()
	for peer_id in peers:
		rpc_id(peer_id, "rpc_die")

func get_health_array() -> Array:
	var output_hp: Array = []
	for i in range(hp):
		output_hp.append(0)
	return output_hp

@rpc("any_peer", "call_local", "reliable")
func rpc_die():
	dead = true
	queue_free()

func take_knockback(what: Vector2):
	velocity += what
