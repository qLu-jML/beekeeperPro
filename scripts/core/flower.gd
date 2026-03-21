extends Node2D

var current_day = 0
var is_seeding = false

# Called when the node is added to the scene.
func _ready():
	update_appearance()

func update_appearance():
	var stage_label = get_node_or_null("Placeholder/StageLabel")
	if stage_label != null:
		if is_seeding:
			stage_label.text = "Dry (Seeding)"
			stage_label.modulate = Color(0.6, 0.4, 0.2) # Browned withered state
		elif current_day < 2:
			stage_label.text = "Seed"
		elif current_day < 7:
			stage_label.text = "Sprout"
		elif current_day < 10:
			stage_label.text = "Growing"
		else:
			stage_label.text = "Mature"
	else:
		print("ERROR: StageLabel not found!")

# Fallback for unconnected advancement
func advance_day():
	current_day += 1
	update_appearance()

# Global world-driven advancement
func advance_day_with_global(global_day: int):
	current_day += 1
	
	# Godot seasons: 0-29(Spring), 30-59(Summer), 60-89(Autumn), 90-119(Winter)
	# Plants aggressively wither and formulate harvestable seed pods strictly entering Autumn
	var day_in_year = global_day % 120
	if day_in_year >= 60 and day_in_year <= 119:
		is_seeding = true
		
	update_appearance()

func harvest_seeds() -> int:
	if is_seeding:
		# Flower shatters on harvest, freeing the dirt block
		var yield_amount = randi_range(2, 4)
		queue_free()
		return yield_amount
	return 0

# Example connection for button pressed signal
func _on_next_day_button_pressed():
	advance_day()  # Call advance_day when the button is pressed
