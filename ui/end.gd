extends Control


@export var address_theme: Theme = null

var reward_requestor: HTTPRequest = HTTPRequest.new()
var board_requestor: HTTPRequest = HTTPRequest.new()
var prefix: String = "[shake][center]"
var suffix: String = "[/center][/shake]"

const MAIN_SCENE_PATH = "res://multiplayer/UI/main_menu.tscn"
const SERVER_URL = "http://localhost:3000"

func _ready() -> void:
	add_child(reward_requestor)
	add_child(board_requestor)
	
	reward_requestor.request_completed.connect(_on_distribute_rewards_completed)
	board_requestor.request_completed.connect(_on_leaderboard_returned)
	
	if Game.is_multiplayer:
		var these_stats: PlayerStats = PlayerManager.players[PlayerManager.get_current_player_index()]
		print("Current player stats: ", these_stats)
		if these_stats.lives.size() > 0:
			%announcement.text = "%s%s%s" % [prefix, "You win!", suffix]
			print("Player 1 wins! Address: ", these_stats.address)  # Debugging line
			_distribute_rewards(these_stats.address)
		else:
			%announcement.text = "%s%s%s" % [prefix, "You got rekt fren!", suffix]
	else:
		var winner = PlayerManager.get_living_players()[0]
		if winner:
			print("Winner object: ", winner)  # Debug the winner object
			print("Winner address: ", winner.address)  # Check if the address is missing
			%announcement.text = "%s%s%s" % [prefix, "Player %s is the GOTCHICHAIN BATTLECHAMP!" % (winner.controller + 1), suffix]
			if winner.address == "" or winner.address == null:
				print("Error: Winner address is empty or null, cannot distribute rewards.")  # Handle the missing address
				_request_leaderboard()
			else:
				if winner.address != "":
					%address.show()
					%address.text = "Address: %s" % winner.address
				print("Winner is Player %s with address: %s" % [winner.controller, winner.address])  # Debugging line
				_distribute_rewards(winner.address)
		else:
			print("No living players found!")  # Debugging line
			%announcement.text = "%s%s%s" % [prefix, "No winner found!", suffix]
			
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

func _request_leaderboard():
	board_requestor.request("%s/leaderboard" % [SERVER_URL])

func _add_leaderboard_entry(what: Dictionary, pos: int):
	var address: String = what["address"]
	var winnings: int = what["winnings"]
	var output: String = "" % [address, winnings]
	
	var hbox: HBoxContainer = HBoxContainer.new()
	%leaderboard.add_child(hbox)
	
	var numbers: Label = Label.new()
	numbers.text = "%s: %s GLTR" % [pos, winnings]
	hbox.add_child(numbers)
	
	var address_label: Label = Label.new()
	address_label.text = " - %s" % [address]
	address_label.theme = address_theme
	hbox.add_child(address_label)

func _distribute_rewards(winner_address: String) -> void:
	if winner_address == "" or winner_address == null:
		print("Error: Winner address is empty or null, cannot distribute rewards.")
		return
	
	print("Winner address: ", winner_address)  # Debugging line
	var url = "%s/game_over" % SERVER_URL
	var data = {
		"winner": winner_address
	}
	print("Sending request to URL: ", url)
	print("Request data: ", JSON.stringify(data))
	var headers = ["Content-Type: application/json"]  # Ensure the correct headers are set
	var err = reward_requestor.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(data))
	if err != OK:
		print("Failed to send request: ", err)
	else:
		%button.disabled = true
		%status.text = "Sending prize..."
		%status.show()

func _on_distribute_rewards_completed(_result, response_code, _headers, body):
	print("Rewards response code: ", response_code)
	print("Response body: ", body.get_string_from_utf8())
	if response_code == 200:
		print("Rewards distributed successfully")
		%status.text = "Sent prize!"
	else:
		print("Failed to distribute rewards")
		%status.text = "Failed to send :("
	%button.disabled = false
	_request_leaderboard()

func _on_leaderboard_returned(_result, response_code, _headers, body):
	print("Leaderboard response code: ", response_code)
	var body_string: String = body.get_string_from_utf8()
	print("Response body: ", body_string)
	
	if response_code == 200:
		var title: Label = Label.new()
		title.text = "THE GREATEST CHAMPS"
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		%leaderboard.add_child(title)
		
		var board: Dictionary = JSON.parse_string(body_string)
		print("Response dictionary: %s" % board)
		var winners: Array = board["leaderboard"]
		for i in range(winners.size()):
			_add_leaderboard_entry(winners[i], i+1)

func _on_game_over(winner: String, amount_won: float, amount_bet: float) -> void:
	print("Game over. Winner: ", winner, " Amount won: ", amount_won, " Amount bet: ", amount_bet)
	%status.text = "Winner: " + winner + "\nAmount won: " + str(amount_won) + " GLTR\nAmount bet: " + str(amount_bet) + " GLTR"
	%button.disabled = false
