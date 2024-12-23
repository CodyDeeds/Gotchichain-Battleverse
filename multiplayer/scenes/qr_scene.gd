extends Control

@export var check_interval: float = 5.0  # Interval in seconds for checking deposits
@export var deposit_check_url: String = "http://localhost:3000/check_deposits"  # URL to check deposits

# References to UI elements and nodes
@onready var texture_rect: TextureRect = %image
@onready var log_list: Control = %log_list
@onready var http_request: HTTPRequest = $http_request
@onready var timer: Timer = $timer

func _ready():
	print("QR Scene ready, initializing...")
	
	# Connect HTTPRequest signal using Godot 4's syntax
	http_request.request_completed.connect(_on_deposit_request_completed)
	
	# Setup and start the timer
	timer.wait_time = check_interval
	timer.timeout.connect(_check_for_deposits)
	timer.start()
	
	# Initial deposit check
	_check_for_deposits.call_deferred()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("test"):
		PlayerManager.get_player(0).bet = 1000
		PlayerManager.get_player(1).bet = 2000
		_start_game()

# Function to check for deposits
func _check_for_deposits() -> void:
	print("Checking for deposits...")
	var err = http_request.request(deposit_check_url)
	if err != OK:
		print("Failed to send deposit check request: ", err)
		_update_log("Failed to send deposit check request.")

# Function to handle deposit request response
func _on_deposit_request_completed(_result: int, response_code: int, _headers: Array, body: PackedByteArray) -> void:
	print("Deposit Request completed with response code: ", response_code)
	var body_str = body.get_string_from_utf8()
	print("Raw Deposit Response Body: ", body_str)

	if response_code == 200:
		var json = JSON.new()
		var parse_result = json.parse(body_str)
		if parse_result != OK:
			print("JSON Parsing Error: ", json.error_string)
			_update_log("Error parsing deposit JSON response.")
			return

		var response_data = json.get_data()
		print("Parsed Response Data: ", response_data)
		if typeof(response_data) == TYPE_DICTIONARY and response_data.has("result"):
			match response_data["result"]:
				"player1_ready":
					if response_data.has("player1") and response_data.has("player1Bet"):
						var player1_address = response_data["player1"]
						var player1_bet = response_data["player1Bet"]
						print("Player 1 Address: ", player1_address, " Bet: ", player1_bet)
						_update_log("Player 1 Address: " + player1_address + " is ready with bet: " + str(player1_bet) + " GLTR.")
						PlayerManager.get_player(0).address = player1_address
				"player2_ready":
					if response_data.has("player2") and response_data.has("player2Bet"):
						var player2_address = response_data["player2"]
						var player2_bet = response_data["player2Bet"]
						print("Player 2 Address: ", player2_address, " Bet: ", player2_bet)
						_update_log("Player 2 Address: " + player2_address + " is ready with bet: " + str(player2_bet) + " GLTR.")
						PlayerManager.get_player(1).address = player2_address
				"deposits_confirmed":
					print("Deposits made, starting the game...")
					_update_log("Deposits made, starting the game...")
					
					if response_data.has("player1") and response_data.has("player1Bet"):
						var player1_address = response_data["player1"]
						var player1_bet = response_data["player1Bet"]
						print("Player 1 Address: ", player1_address, " Bet: ", player1_bet)
						_update_log("Player 1 Address: " + player1_address + " is ready with bet: " + str(player1_bet) + " GLTR.")
						PlayerManager.get_player(0).bet = player1_bet
						PlayerManager.get_player(0).address = player1_address
					if response_data.has("player2") and response_data.has("player2Bet"):
						var player2_address = response_data["player2"]
						var player2_bet = response_data["player2Bet"]
						print("Player 2 Address: ", player2_address, " Bet: ", player2_bet)
						_update_log("Player 2 Address: " + player2_address + " is ready with bet: " + str(player2_bet) + " GLTR.")
						PlayerManager.get_player(1).bet = player2_bet
						PlayerManager.get_player(1).address = player2_address
					
					_start_game()
				"waiting_for_deposits":
					print("Waiting for deposits...")
					_update_log("Waiting for deposits...")
				_:
					print("Unknown result: ", response_data["result"])
					_update_log("Unknown result: " + response_data["result"])
		else:
			print("Invalid deposit response format.")
			_update_log("Invalid deposit response format.")
	else:
		print("Server error on deposit check. Response code: ", response_code)
		_update_log("Server error with response code: " + str(response_code))

# Function to start the game
func _start_game() -> void:
	print("Starting game in local mode...")
	Game.is_multiplayer = false  # Ensure local mode is set
	
	var scene_path = "res://ui/wearable_selection.tscn"
	var result = get_tree().change_scene_to_file(scene_path)
	print("Change scene result: ", result)
	if result != OK:
		print("Failed to change scene: ", result)
		_update_log("Failed to change scene: Error " + str(result))
	else:
		print("Successfully changed to game holder scene.")

func _get_last_label() -> Label:
	var line_count: int = %log_list.get_child_count()
	if line_count > 0:
		var last_container: Control = %log_list.get_child(line_count - 1)
		return last_container.get_child(0)
	else:
		return null


# Function to update the log label with new messages
func _update_log(message: String) -> void:
	print("Updating log: ", message)
	if message == "":
		return
	
	# Function to resize the container of the label to the size of the label
	var resize_container: Callable = func(what: Control):
		if what.get_child_count() > 0:
			what.custom_minimum_size.y = what.get_child(0).size.y
	
	# Function to animate a label on arrival
	var animate_label: Callable = func(what: Label):
		var animation_duration: float = 0.5
		var tween: Tween = create_tween()
		# Scale
		what.scale = Vector2(1.2, 1.2)
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		tween.tween_property(what, ^"scale", Vector2(1, 1), animation_duration)
		# Position
		what.position.x = 48 + 128
		tween.parallel().tween_property(what, ^"position", Vector2(48, 0), animation_duration)
		# Rotation
		what.rotation = randf_range(-.4, .4)
		tween.parallel().tween_property(what, ^"rotation", 0, animation_duration)
	
	# Check what the last message was
	var last_message: String = ""
	var last_label: Label = _get_last_label()
	if last_label:
		last_message = last_label.text
	
	if message == last_message:
		# If the new message is the same as the last message, simply animate the existing last message without adding anything
		animate_label.call(last_label)
	else:
		# Create and configure the label container
		var log_container: Control = Control.new()
		log_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		# Create and configure the label itself
		var log_label: Label = Label.new()
		log_label.text = message
		log_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		log_label.pivot_offset = log_label.size / 2
		
		# Animate the label on arrival
		animate_label.call(log_label)
		
		# Place the new nodes into the scene
		log_container.add_child(log_label)
		log_list.add_child(log_container)
		
		# Call the aforementioned resizing function
		resize_container.bind(log_container).call_deferred()
