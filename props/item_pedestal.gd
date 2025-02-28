extends Node2D

## Speed with which items jump when they appear from this pedestal
@export var item_jump_speed := 200.0
## If set, this item will always spawn from this pedestal. If not, will randomly select from [code]items[/code]
@export var force_item: PackedScene = null
## Range at which players will see the tooltip
@export var tooltip_range := 32.0  # Reduced from 64.0 to create a much tighter detection zone
## Vertical offset for tooltip position
@export var tooltip_offset := 150.0  # Increased to position higher above character and P1/P2 labels

# Dictionary of weapon descriptions for tooltips
var weapon_info = {
	"res://items/uranium_rod.tscn": "Pixelrods of Power\nHold near enemies until it glows to deal damage",
	"res://items/gun_basic.tscn": "Spellcaster's Wand\nPress attack button to fire magic bolts",
	"res://items/gun_triple.tscn": "Tri-Aave Blaster\nPress attack to fire multiple magical shots",
	"res://items/mechanical_claw.tscn": "Gotchigrabber 3000\nGrabs and pulls enemies closer",
	"res://items/grenade.tscn": "Grenade\nThrow at enemies and take cover",
	"res://items/grenade_large.tscn": "Mega Grenade\nBigger blast radius - throw and move away",
	"res://items/rekt_sign.tscn": "REKT Sign\nDelivers devastating melee blows",
	"res://items/sushi_knife.tscn": "Phantom Edge Blade\nQuick cutting attacks",
	"res://items/baable_gum.tscn": "Baable Gum\nSlows down enemies",
	"res://items/captain_aave_shield.tscn": "Captain Aave Shield\nBlocks incoming attacks",
	"res://items/walkie_talkie.tscn": "Ethereal Whisperer\nCommunication and distraction device",
	"res://items/pitchfork.tscn": "Crypto Harvester\nThrust forward to impale enemies",
	"res://items/aantenna_bot.tscn": "Aantenna Bot\nRemote-controlled attack robot"
}

var current_item: Item = null
var tooltip_label = null

func _ready():
	if multiplayer.is_server():
		$spawn_timer.start()
	
	# Make sure we're in the pedestals group for proximity comparison
	if not is_in_group("pedestals"):
		add_to_group("pedestals")
	
	# Create a simple tooltip label
	tooltip_label = Label.new()
	tooltip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tooltip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Add semi-transparent background panel for better readability
	var panel = Panel.new()
	panel.name = "background"
	
	# Set up a stylebox for the panel background
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.7)  # Semi-transparent black background
	style.border_width_bottom = 2
	style.border_width_top = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = Color(1.0, 0.35, 0.75, 0.8)  # Hot pink border to match theme
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	
	panel.add_theme_stylebox_override("panel", style)
	tooltip_label.add_child(panel)
	panel.show_behind_parent = true
	
	# Hot pink color to match the platforms in the game, but brighter for better contrast
	var bright_pink = Color(1.0, 0.6, 0.9)  # Brighter pink for better contrast
	tooltip_label.add_theme_color_override("font_color", bright_pink)
	tooltip_label.add_theme_font_size_override("font_size", 18)  # Slightly larger font
	
	# Enhance outline for better readability
	tooltip_label.add_theme_constant_override("outline_size", 4)  # Thicker outline
	tooltip_label.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.1, 1.0))  # Very dark purple outline
	
	# Try to make the text bold
	tooltip_label.set("theme_override_fonts/bold_font", load("res://fonts/default_bold.tres") if ResourceLoader.exists("res://fonts/default_bold.tres") else null)
	
	tooltip_label.visible = false
	
	# Center the label
	add_child(tooltip_label)
	tooltip_label.position.x = 0  # Ensure centered horizontally
	tooltip_label.position.y = -tooltip_offset  # Higher vertical position
	
	# Ensure the label is centered on itself
	tooltip_label.pivot_offset = Vector2(tooltip_label.size.x / 2, tooltip_label.size.y / 2)

func _process(_delta: float) -> void:
	var player_nearby = is_player_in_range()
	
	if player_nearby and Game.show_tooltips:  # Check global setting
		if force_item != null:
			show_tooltip(force_item.resource_path)
		elif current_item != null:
			show_tooltip(current_item.scene_file_path)
		else:
			hide_tooltip()
	else:
		hide_tooltip()
	
	# Ensure tooltip stays centered even if its size changes
	if tooltip_label and tooltip_label.visible:
		tooltip_label.position.x = 0
		# Get the center of the sprite or a custom position if needed
		var sprite_center = $sprite.position.x if has_node("sprite") else 0
		tooltip_label.position.x = sprite_center
		
		# Properly center the tooltip based on its current size
		var half_width = tooltip_label.get_minimum_size().x / 2
		tooltip_label.position.x -= half_width

func show_tooltip(item_path: String) -> void:
	if !tooltip_label or !Game.show_tooltips:  # Don't show if tooltips are disabled
		return
	
	# Get weapon information
	var text = ""
	if weapon_info.has(item_path):
		text = weapon_info[item_path]
	else:
		var item_name = item_path.get_file().get_basename().capitalize()
		text = item_name + "\nExperiment to discover its abilities"
	
	# Set the label text and display it
	tooltip_label.text = text
	tooltip_label.visible = true
	
	# Force layout update to get correct size
	tooltip_label.size = Vector2.ZERO
	tooltip_label.force_update_transform()
	
	# Update the background panel to match the size of the text
	if tooltip_label.has_node("background"):
		var panel = tooltip_label.get_node("background")
		if is_instance_valid(get_tree()):
			await get_tree().process_frame  # Wait one frame for label size to update
			if is_instance_valid(panel) and is_instance_valid(tooltip_label):
				panel.size = tooltip_label.size + Vector2(20, 16)  # Add padding
				panel.position = Vector2(-10, -8)  # Center the panel

func hide_tooltip() -> void:
	if tooltip_label:
		tooltip_label.visible = false

func spawn_item():
	var this_item: PackedScene
	if force_item:
		this_item = force_item
	else:
		this_item = BigData.get_random_item_from_pool(Item.POOLS.PEDESTAL)
	
	var new_item: Item = Game.create_instance(this_item)
	Game.deploy_instance(new_item, position)
	new_item.apply_central_impulse(Vector2(0, -item_jump_speed))
	new_item.tree_exiting.connect(_on_item_slain)
	current_item = new_item

func _on_spawn_timer_timeout() -> void:
	spawn_item()

func _on_item_slain():
	current_item = null
	if multiplayer.is_server():
		$spawn_timer.start()

## Check if any player is within tooltip range of this pedestal
func is_player_in_range() -> bool:
	for player in get_tree().get_nodes_in_group("players"):
		if is_instance_valid(player):
			var distance = player.global_position.distance_to(global_position)
			
			# Check if this pedestal is the closest one to the player
			if distance <= tooltip_range:
				# Find if there's any closer pedestal
				var pedestals = get_tree().get_nodes_in_group("pedestals")
				var is_closest = true
				
				for other_pedestal in pedestals:
					if other_pedestal != self and is_instance_valid(other_pedestal):
						var other_distance = player.global_position.distance_to(other_pedestal.global_position)
						if other_distance < distance:
							is_closest = false
							break
				
				# Only show tooltip if this is the closest pedestal to the player
				return is_closest
	return false
