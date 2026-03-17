extends CanvasLayer

@onready var hive = get_node("../World/Hive")
@onready var day_label: Label = $DayLabel
@onready var resource_label: Label = $ResourceLabel
@onready var next_day_button: Button = $NextDayButton

func _ready() -> void:
	print("HUD script ready on node: ", name)
	print("Hive reference: ", hive)
	print("DayLabel: ", day_label)
	print("ResourceLabel: ", resource_label)
	print("NextDayButton: ", next_day_button)
	
	if not hive:
		push_error("Hive not found at ../World/Hive")
		return
	
	if next_day_button:
		# Safety: disconnect old if any
		if next_day_button.pressed.is_connected(_on_next_day_button_pressed):
			next_day_button.pressed.disconnect(_on_next_day_button_pressed)
		
		next_day_button.pressed.connect(_on_next_day_button_pressed)
		print("Button pressed signal connected")
	else:
		push_error("NextDayButton not found as child")
	
	_update_ui_labels()  # initial update


func _on_next_day_button_pressed() -> void:
	print("BUTTON CLICK DETECTED - advancing world")
	
	hive.advance_day()
	
	var flowers = get_tree().get_nodes_in_group("flowers")
	print("=== FLOWER CHECK ===")
	print("Found flowers count:", flowers.size())
	if flowers.size() == 0:
		print("WARNING: No nodes in group 'flowers' — check group membership!")
	else:
		print("Advancing", flowers.size(), "flowers")
		for flower in flowers:
			print("  - Advancing flower:", flower.flower_name if "flower_name" in flower else "unnamed")
			flower.advance_day()
	
	_update_ui_labels()


func _update_ui_labels() -> void:
	print("Updating UI labels - day: ", hive.days_elapsed)
	
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
