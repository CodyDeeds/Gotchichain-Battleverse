extends Control

const MAIN_SCENE_PATH = "res://multiplayer/UI/main_menu.tscn"
const SERVER_URL = "http://localhost:3000"

func _ready() -> void:
	if Game.is_multiplayer:
		var these_stats: PlayerStats = PlayerManager.players[PlayerManager.get_current_player_index()]
		print("Current player stats: ", these_stats)
		if these_stats.lives.size() > 0:
			%announcement.text = "You win!"
			print("Player 1 wins! Address: ", these_stats.address)  # Debugging line
			_distribute_rewards(these_stats.address)
		else:
			%announcement.text = "You got rekt fren!"
	else:
		var winner = PlayerManager.get_living_players()[0]
		if winner:
			print("Winner object: ", winner)  # Debug the winner object
			print("Winner address: ", winner.address)  # Check if the address is missing
			%announcement.text = "Player %s is the GOTCHICHAIN BATTLECHAMP!" % (winner.controller + 1)
			if winner.address == "" or winner.address == null:
				print("Error: Winner address is empty or null, cannot distribute rewards.")  # Handle the missing address
			else:
				if winner.address != "":
					%address.show()
					%address.text = "Address: %s" % winner.address
				print("Winner is Player %s with address: %s" % [winner.controller, winner.address])  # Debugging line
				_distribute_rewards(winner.address)
		else:
			print("No living players found!")  # Debugging line
			%announcement.text = "No winner found!"
			
	%button.grab_focus()
	%button.pressed.connect(_on_button_pressed)

func _on_button_pressed() -> void:
	restart_game()

func restart_game():
	log_out()
	get_tree().change_scene_to_file(MAIN_SCENE_PATH)

func log_out():
	var mattoha_client = MattohaSystem.Client
	if mattoha_client:
		mattoha_client.call("LeaveLobby")
		mattoha_client.set("CurrentPlayer", Dictionary())
		mattoha_client.set("CurrentLobby", Dictionary())
		mattoha_client.set("CurrentLobbyPlayers", Dictionary())
		print("Player logged out.")
	else:
		print("MattohaClient instance not found")

func _distribute_rewards(winner_address: String) -> void:
	if winner_address == "" or winner_address == null:
		print("Error: Winner address is empty or null, cannot distribute rewards.")
		return
	
	print("Winner address: ", winner_address)  # Debugging line
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_distribute_rewards_completed)
	var url = "%s/game_over" % SERVER_URL
	var data = {
		"winner": winner_address
	}
	print("Sending request to URL: ", url)
	print("Request data: ", JSON.stringify(data))
	var headers = ["Content-Type: application/json"]  # Ensure the correct headers are set
	var err = http_request.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(data))
	if err != OK:
		print("Failed to send request: ", err)
	else:
		%button.disabled = true
		%status.text = "Sending prize..."
		%status.show()

func _on_distribute_rewards_completed(_result, response_code, _headers, body):
	print("Response code: ", response_code)
	print("Response body: ", body.get_string_from_utf8())
	if response_code == 200:
		print("Rewards distributed successfully")
		%status.text = "Sent prize!"
	else:
		print("Failed to distribute rewards")
		%status.text = "Failed to send :("
	%button.disabled = false
