extends Node2D
class_name Hive

signal day_advanced(new_day: int)

# Colony stats
var eggs: int = 2000
var nurseBee: int = 3000
var workerBee: int = 6000
var drone: int = 100
var queen: bool = true

var colony_population: int:
	get:
		return nurseBee + workerBee + drone + (1 if queen else 0)

var queen_age: int = 0          # in days
var honey_stores: float = 20.0  # in pounds
var pollen_stores: float = 5.0
var mite_level: float = 0.0     # 0–100 percentage

# Health status
var diseases: Array = []

# Time tracking
var days_elapsed: int = 0

@onready var stat_label = $Label

func _ready() -> void:
	add_to_group("hive")
	# ... rest of your code
	print("Hive initialized with %d bees" % colony_population)
	update_label()

func advance_day() -> void:
	days_elapsed += 1
	queen_age += 1
	
	# Simple population dynamics
	if queen:
		var eggs_laid = 1500  # Queen lays ~1500 eggs/day
		eggs += eggs_laid
	
	var new_nurses = int(eggs * 0.2)
	eggs -= new_nurses
	nurseBee += new_nurses
	
	var new_workers = int(nurseBee * 0.1)
	nurseBee -= new_workers
	workerBee += new_workers
	
	# Natural mortality (~3% daily turnover)
	workerBee -= int(workerBee * 0.03)
	if drone > 0:
		drone -= int(drone * 0.05)
	
	# Resource consumption
	honey_stores -= 0.5
	pollen_stores -= 0.2
	
	update_label()
	day_advanced.emit(days_elapsed)

func harvest_honey() -> float:
	if honey_stores > 0:
		var amount = honey_stores
		honey_stores = 0.0
		update_label()
		return amount
	return 0.0

func update_label() -> void:
	if stat_label:
		stat_label.text = "Q:%s | E:%d\nN:%d | W:%d | D:%d\nHon: %.1f" % [
			"Y" if queen else "N",
			eggs,
			nurseBee,
			workerBee,
			drone,
			honey_stores
		]

# ────────────────────────────────────────────────
# Inspection (still useful for debugging)
# ────────────────────────────────────────────────

func inspect_hive() -> void:
	print("=== HIVE INSPECTION ===")
	print("Population: %d bees" % colony_population)
	print("Queen: %s (Age: %d days)" % ["Present" if queen else "Missing", queen_age])
	print("Eggs: %d | Nurses: %d | Workers: %d | Drones: %d" % [eggs, nurseBee, workerBee, drone])
	print("Honey: %.1f lbs | Pollen: %.1f lbs" % [honey_stores, pollen_stores])
	print("Mite Level: %.1f%%" % mite_level)
	print("=====================")

func _on_area_2d_input_event(_viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		inspect_hive()
