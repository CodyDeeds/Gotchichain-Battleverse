extends Control

const MAIN_SCENE_PATH = "res://multiplayer/UI/main_menu.tscn"
const SERVER_URL = "http://localhost:3000"

func _ready() -> void:
	if Game.is_multiplayer:
		var these_stats: PlayerStats = PlayerManager.players[ PlayerManager.get_current_player_index() ]
		if these_stats.lives.size() > 0:
			%announcement.text = "You win!"
			_distribute_rewards(these_stats.controller)
		else:
			%announcement.text = "You got rekt fren!"
	else:
		var winner = PlayerManager.get_living_players()[0]
		%announcement.text = "Player %s is the winner!" % winner.controller
		_distribute_rewards(winner.controller)

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

func _distribute_rewards(winner: int) -> void:
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_distribute_rewards_completed)
	var winner_address: String = ""
	var url = "%s/distribute_rewards" % SERVER_URL
	var data = {"winnerAddress": winner_address}
	http_request.request(url, [], HTTPClient.METHOD_POST, JSON.stringify(data))

func _on_distribute_rewards_completed(result, response_code, headers, body):
	if response_code == 200:
		print("Rewards distributed successfully")
	else:
		print("Failed to distribute rewards")
