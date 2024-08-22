extends Node

# Preload the background music file
@export var music_file: AudioStream = preload("res://audio/music/PixelBattle.ogg")

# Define an AudioStreamPlayer
var music_player: AudioStreamPlayer = null
var is_muted: bool = false

func _ready():
	# Initialize and configure the music player
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	music_player.stream = music_file
	
	# Ensure the music stream is set to loop
	if music_player.stream is AudioStream:
		var stream = music_player.stream as AudioStream
		stream.loop = true
	
	# Adjust the volume
	music_player.volume_db = -20  # Adjust volume level (lower value for quieter sound)
	
	# Play the music
	music_player.play()

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == Key.KEY_M:
		toggle_mute()

func toggle_mute():
	is_muted = not is_muted
	music_player.volume_db = -80 if is_muted else -20  # Mute if muted, else set to normal volume
