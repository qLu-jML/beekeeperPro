extends CanvasLayer

# References to the Hive node (adjust path if your hierarchy is different)
@onready var hive: Node = get_node("../World/Hive")

# UI elements (children of this CanvasLayer)
@onready var day_label: Label = $DayLabel
@onready var resource_label: Label = $ResourceLabel
@onready var next_day_button: Button = $NextDayButton

func _ready() -> void:
	if not hive:
		push_error("Hive node not found at path ../World/Hive")
		return
	
	if not hive.has_method("advance_day"):
		push_error("Hive node does not have advance_day() method")
		return
	
	# Connect the button press
	next_day_button.pressed.connect(_on_next_day_button_pressed)
	
	# Optional: listen to a signal from hive if you add one later
	# if hive.has_signal("day_advanced"):
	#     hive.day_advanced.connect(_on_hive_day_advanced)
	
	# Initial UI update
	_update_ui()


func _on_next_day_button_pressed() -> void:
	hive.advance_day()
	_update_ui()


# Optional: if you later add a day_advanced signal in hive.gd
# func _on_hive_day_advanced(_new_day: int) -> void:
#     _update_ui()


func _update_ui() -> void:
	if day_label:
		day_label.text = "Day: %d - %s" % [hive.days_elapsed, get_season_name()]
	
	if resource_label:
		resource_label.text = "Population: %d bees\nHoney: %.1f lbs\nPollen: %.1f lbs\nBrood: %d cells" % [
			hive.colony_population,
			hive.honey_stores,
			hive.pollen_stores,
			hive.brood_count
		]


func get_season_name() -> String:
	var day_in_year = hive.days_elapsed % 120
	if day_in_year < 30:
		return "Spring"
	elif day_in_year < 60:
		return "Summer"
	elif day_in_year < 90:
		return "Autumn"
	else:
		return "Winter"
