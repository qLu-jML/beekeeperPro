extends Node2D
class_name Hive

signal day_advanced(new_day: int)

# Colony stats
var colony_population: int = 10000
var queen_age: int = 0          # in days
var honey_stores: float = 20.0  # in pounds
var pollen_stores: float = 5.0
var brood_count: int = 5000
var mite_level: float = 0.0     # 0–100 percentage

# Health status
var has_queen: bool = true
var diseases: Array = []

# Time tracking
var days_elapsed: int = 0

func _ready() -> void:
	add_to_group("hive")
	# ... rest of your code
	print("Hive initialized with %d bees" % colony_population)

func advance_day() -> void:
	days_elapsed += 1
	queen_age += 1
	
	# Simple population dynamics
	if has_queen and colony_population < 60000:
		var eggs_laid = 1500  # Queen lays ~1500 eggs/day
		colony_population += eggs_laid
	
	# Natural mortality (~3% daily turnover)
	var daily_loss = colony_population * 0.03
	colony_population -= int(daily_loss)
	
	# Resource consumption
	honey_stores -= 0.5
	pollen_stores -= 0.2
	
	print("Day %d: Population now %d | Honey: %.1f | Pollen: %.1f" % [
		days_elapsed, colony_population, honey_stores, pollen_stores
	])
	
	day_advanced.emit(days_elapsed)

# ────────────────────────────────────────────────
# Inspection (still useful for debugging)
# ────────────────────────────────────────────────

func inspect_hive() -> void:
	print("=== HIVE INSPECTION ===")
	print("Population: %d bees" % colony_population)
	print("Queen: %s (Age: %d days)" % ["Present" if has_queen else "Missing", queen_age])
	print("Honey: %.1f lbs" % honey_stores)
	print("Pollen: %.1f lbs" % pollen_stores)
	print("Brood: %d cells" % brood_count)
	print("Mite Level: %.1f%%" % mite_level)
	print("=====================")

func _on_area_2d_input_event(_viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		inspect_hive()
