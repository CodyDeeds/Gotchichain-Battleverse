extends Control


var current_ready_text := 0

const ready_texts = [
	"[center][shake]GEIST FIGHT IN 3...[/shake][/center]",
	"[center][shake]GEIST FIGHT IN 2...[/shake][/center]",
	"[center][shake]GEIST FIGHT IN 1...[/shake][/center]"
]


func _ready() -> void:
	for this_selection in %list.get_children():
		this_selection.ready_changed.connect(_on_ready_changed)
		this_selection.father = self


func ready_countdown():
	for this_selection in %list.get_children():
		this_selection.locked = true
		this_selection.selected_row = -1
	%ready_timer.start()
	show_ready_text()

func proceed():
	pass_wearables_to_manager()
	get_tree().change_scene_to_file("res://multiplayer/maps/multiplayer_arena.tscn")

func pass_wearables_to_manager():
	for i in %list.get_child_count():
		var this_selection = %list.get_child(i)
		PlayerManager.get_player(i).body_wearable = this_selection.body_wearable
		PlayerManager.get_player(i).head_wearable = this_selection.head_wearable

func show_ready_text():
	%status.text = ready_texts[current_ready_text]

func _on_ready_changed():
	if OS.is_debug_build():
		ready_countdown()
	
	for this_selection in %list.get_children():
		if !this_selection.is_ready:
			return
	
	ready_countdown()


func _on_ready_timer_timeout() -> void:
	current_ready_text += 1
	if current_ready_text >= ready_texts.size():
		proceed()
	else:
		show_ready_text()
