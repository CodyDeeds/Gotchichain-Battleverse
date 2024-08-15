class_name Entity
extends CharacterBody2D

var max_hp := 5.0
var hp := max_hp
var limit_hp := true
var dead := false

func set_hp(what: float):
	hp = what

	if hp <= 0&&!dead:
		die()

	if limit_hp:
		hp = min(hp, max_hp)

func take_damage(what: float, can_heal: bool=true):
	if !can_heal:
		what = max(what, 0)

	set_hp(hp - what)

func die():
	var peers = MattohaSystem.Client.GetLobbyPlayersIds()
	for peer_id in peers:
		rpc_id(peer_id, "rpc_die")

@rpc("any_peer", "call_local", "reliable")
func rpc_die():
	dead = true
	queue_free()

func take_knockback(what: Vector2):
	velocity += what
