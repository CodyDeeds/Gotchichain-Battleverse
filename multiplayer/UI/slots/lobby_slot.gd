extends HBoxContainer

var lobby_dict

func _ready():
    $Name.text = lobby_dict["Name"]
    $Players.text = "%d / %d" % [lobby_dict["PlayersCount"],lobby_dict["MaxPlayers"]]

func _on_join_button_pressed():
    MattohaSystem.Client.JoinLobby(lobby_dict["Id"])