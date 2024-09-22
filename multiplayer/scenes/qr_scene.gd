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
	
	# Display the QR code
	var qr_texture = preload("res://qr.png")
	texture_rect.texture = qr_texture
	
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
		print("Parsed Response Data: ", response_data)  # Add this line
		if typeof(response_data) == TYPE_DICTIONARY and response_data.has("result"):
			match response_data["result"]:
				"deposits_confirmed":
					print("Deposits made, starting the game...")
					_update_log("Deposits made, starting the game...")

					# Log player addresses if they exist in the response
					if response_data.has("player1") and response_data.has("player2"):
						var player1_address = response_data["player1"]
						var player2_address = response_data["player2"]
						print("Player 1 Address: ", player1_address)
						print("Player 2 Address: ", player2_address)
						_update_log("Player 1 Address: " + player1_address)
						_update_log("Player 2 Address: " + player2_address)
					else:
						print("Player addresses not found in the response")
						_update_log("Player addresses not found")
					
					_start_game()
				_:
					print("Waiting for deposits...")
					_update_log("Waiting for deposits...")
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
	
	var scene_path = "res://multiplayer/maps/multiplayer_arena.tscn"
	var result = get_tree().change_scene_to_file(scene_path)
	print("Change scene result: ", result)
	if result != OK:
		print("Failed to change scene: ", result)
		_update_log("Failed to change scene: Error " + str(result))
	else:
		print("Successfully changed to game holder scene.")

# Function to update the log label with new messages
func _update_log(message: String) -> void:
	print("Updating log: ", message)
	if message == "":
		return
	
	# Create and configure the label container
	var log_container: Control = Control.new()
	log_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Create and configure the label itself
	var log_label: Label = Label.new()
	log_label.text = message
	log_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Place the new nodes into the scene
	log_container.add_child(log_label)
	log_list.add_child(log_container)
