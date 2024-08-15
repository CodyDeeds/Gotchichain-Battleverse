@tool
class_name ChargeState
extends State


@export var post_animation := ""
@export var automatically_enter_post := true

var pre := false
var post := false
var post_queued := false

signal pre_finished
signal activated


func _enter():
	super()
	pre = true
	post = false
	post_queued = automatically_enter_post

func _on_animation_finished():
	if post:
		super()
	elif post_queued:
		pre = false
		pre_finished.emit()
		enter_post()
	else:
		pre = false
		pre_finished.emit()


func enter_post():
	if pre:
		post_queued = true
	else:
		post = true
		fsm.play_animation(post_animation)
		activated.emit()
