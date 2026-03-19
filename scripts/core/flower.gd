extends Node2D

var current_day = 0

# Called when the node is added to the scene.
func _ready():
	update_appearance()

func update_appearance():
	var stage_label = get_node("Placeholder/StageLabel")
	if stage_label != null:
		if current_day < 2:
			stage_label.text = "Seed"
		elif current_day < 7:
			stage_label.text = "Sprout"
		elif current_day < 10:
			stage_label.text = "Growing"
		else:
			stage_label.text = "Mature"
	else:
		print("ERROR: StageLabel not found!")

# Function to advance the day
func advance_day():
	current_day += 1
	update_appearance()  # Update the appearance after advancing the day

# Example connection for button pressed signal
func _on_next_day_button_pressed():
	advance_day()  # Call advance_day when the button is pressed
