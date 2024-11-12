extends PanelContainer


enum ROW {
	HEAD,
	BODY,
	MAX
}

@export var selection_colour := Color(1.5, 2, 1.5, 1)

var selected_row: ROW = ROW.HEAD
var head_wearable: Wearable = null
var body_wearable: Wearable = null
var head_index := 0
var body_index := 0
var controller := 0
var is_ready := false
var age := 0.0
var locked := false

var all_heads = BigData.head_wearables.values()
var all_bodies = BigData.body_wearables.values()

const text_unready := "[center]Ready? [img]res://ui/button_a.png[/img][/center]"
const text_ready := "[center][shake]READY![/shake][/center]"

signal ready_changed


func _ready() -> void:
	resized.connect(_on_resized)
	
	all_heads = BigData.head_wearables.values()
	all_bodies = BigData.body_wearables.values()
	
	set_head(all_heads[0])
	set_body(all_bodies[0])
	
	controller = get_index()
	%title.text = "Player %s" % (controller + 1)

func _process(delta: float) -> void:
	age += delta
	var factor := 0.5 + 0.5*sin(age*3)
	var current_colour := Color.WHITE.lerp(selection_colour, factor)
	%head.modulate = Color.WHITE
	%body.modulate = Color.WHITE
	match selected_row:
		ROW.HEAD:
			%head.modulate = current_colour
		ROW.BODY:
			%body.modulate = current_colour

func _input(event: InputEvent) -> void:
	if event.device == controller and !locked:
		if event.is_action_pressed("move_down"):
			selected_row += 1
		if event.is_action_pressed("move_up"):
			selected_row -= 1
		
		selected_row = wrapi(selected_row, 0, ROW.MAX)
		
		if event.is_action_pressed("move_left"):
			match selected_row:
				ROW.HEAD:
					set_head_index(head_index - 1)
				ROW.BODY:
					set_body_index(body_index - 1)
		
		if event.is_action_pressed("move_right"):
			match selected_row:
				ROW.HEAD:
					set_head_index(head_index + 1)
				ROW.BODY:
					set_body_index(body_index + 1)
		
		if event.is_action_pressed("jump"):
			set_ready(!is_ready)


func set_head_index(what: int):
	head_index = wrapi(what, 0, all_heads.size())
	set_head(all_heads[head_index])

func set_body_index(what: int):
	body_index = wrapi(what, 0, all_bodies.size())
	set_body(all_bodies[body_index])

func set_head(what: Wearable):
	head_wearable = what
	%head.texture = what.sprite
	reposition_head.call_deferred()

func set_body(what: Wearable):
	body_wearable = what
	%body.texture = what.sprite
	reposition_body.call_deferred()

func set_ready(what: bool):
	is_ready = what
	
	%status.text = text_ready if is_ready else text_unready
	
	ready_changed.emit()

func reposition_head():
	%head.position = Vector2()
	%head.size = %head.get_parent().size
	if head_wearable:
		%head.position = head_wearable.offset * get_texture_scale(%head)

func reposition_body():
	%body.position = Vector2()
	%body.size = %body.get_parent().size
	if body_wearable:
		%body.position = body_wearable.offset * get_texture_scale(%body)

func get_texture_scale(what: TextureRect) -> float:
	if !what.texture:
		return 1
	
	var texture_scale := what.size / what.texture.get_size()
	return min(texture_scale.x, texture_scale.y)


func _on_resized():
	reposition_head()
	reposition_body()
