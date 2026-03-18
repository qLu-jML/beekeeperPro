extends Node2D

var current_day = 0

# Called when the node is added to the scene.
func _ready():
	update_appearance()

func update_appearance():
	var stage_label = get_node("Placeholder/StageLabel")
	if stage_label != null:
		stage_label.text = "Current Day: %d" % current_day
	else:
		print("ERROR: StageLabel not found!")

# Function to advance the day
func advance_day():
	current_day += 1
	update_appearance()  # Update the appearance after advancing the day

# Example connection for button pressed signal
func _on_next_day_button_pressed():
	advance_day()  # Call advance_day when the button is pressed
