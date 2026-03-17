# TimeManager.gd — global day/time handler for BeeKeeper Pro
extends Node

signal day_advanced(new_day: int)

var current_day: int = 1
var current_season: String = "Spring"  # expand later with your seasons logic

func advance_day() -> void:
	current_day += 1
	
	# Simple seasonal example (you can make this fancier later)
	var day_in_year = current_day % 120  # rough 4 seasons × 30 days
	if day_in_year <= 30:
		current_season = "Spring"
	elif day_in_year <= 60:
		current_season = "Summer"
	elif day_in_year <= 90:
		current_season = "Autumn"
	else:
		current_season = "Winter"
	
	print("🌼 Advanced to Day ", current_day, " — Season: ", current_season)
	
	# This signal tells EVERYTHING (flowers, bees, hives, quests) that a new day happened
	day_advanced.emit(current_day)
	
	# Future hooks go here, e.g.:
	# Inventory.add_honey(5)           # example
	# check_quests()                   # example
