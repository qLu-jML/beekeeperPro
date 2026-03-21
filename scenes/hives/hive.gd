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

# Advanced Simulation Variables
var mites: float = 150.0
var survival_rate: float = 1.0
var mite_crashes: int = 0
var starvation_events: int = 0

# Health status
var diseases: Array = []

# Time tracking
var days_elapsed: int = 0

@onready var stat_label = $Label

func _ready() -> void:
	add_to_group("hive")
	print("Hive initialized with %d bees" % colony_population)
	if stat_label:
		stat_label.add_theme_font_size_override("font_size", 4)
		stat_label.position = Vector2(-16, -28)
		stat_label.custom_minimum_size = Vector2(32, 0)
		stat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		stat_label.z_index = 5
	update_label()

func advance_day() -> void:
	days_elapsed += 1
	queen_age += 1
	
	var season_factor = get_season_factor(days_elapsed)
	
	# Advanced Brood population dynamics
	var new_eggs = 0
	if queen:
		var lay_multiplier = season_factor * maxf(0.0, 1.0 - (mites / 5000.0))
		new_eggs = int(1500.0 * lay_multiplier)
		eggs += new_eggs
	
	var new_nurses = int(eggs * 0.2)
	eggs -= new_nurses
	nurseBee += new_nurses
	
	var new_workers = int(nurseBee * 0.1)
	nurseBee -= new_workers
	workerBee += new_workers
	
	# Natural mortality (~1% daily turnover via python metrics) scaled by their health factor
	workerBee -= int(workerBee * 0.01 * survival_rate)
	if drone > 0:
		drone -= int(drone * 0.05)
	
	# Nectar physics and Seasonal Winter Cluster consumption natively imported
	var nectar_intake = season_factor * (float(workerBee) / 20000.0) * randf_range(0.7, 1.3)
	var honey_produced = nectar_intake * 0.15
	var daily_consumption = get_daily_consumption(float(colony_population), days_elapsed)
	
	honey_stores += honey_produced - daily_consumption
	if honey_stores < 0.0:
		honey_stores = 0.0
		
	pollen_stores -= 0.2
	if pollen_stores < 0.0:
		pollen_stores = 0.0
		
	# Varroa Mite exponential reproduction checks across capped cell count estimations
	var capped = float(new_eggs) * 0.8
	mites += capped * 0.05
	
	# Crash calculations
	if mites > 4000.0:
		survival_rate *= 0.65
		mite_crashes += 1
		mites = 3000.0 # Naturally limit to prevent float explosion
		
	var current_month = (days_elapsed / 30) % 12
	# If deeply starving mid-winter cluster, population radically plummets organically
	if honey_stores < 10.0 and current_month in [0, 1, 11]:
		survival_rate *= 0.5
		starvation_events += 1
	
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
		stat_label.text = "Q:%s E:%d\nW:%d M:%d\nHon:%.1f S:%d%%" % [
			"Y" if queen else "N",
			eggs,
			workerBee,
			int(mites),
			honey_stores,
			int(survival_rate * 100.0)
		]

func get_season_factor(day: int) -> float:
	var month = (day / 30) % 12
	if month in [0, 1, 11]:   # Dec, Jan, Feb
		return 0.1
	if month in [2, 3]:       # Mar, Apr
		return 0.6
	if month in [4, 5, 6, 7, 8]:  # May–Sep
		return 1.0 + randf_range(-0.2, 0.3)
	return 0.4                # Oct, Nov

func get_daily_consumption(size: float, day: int) -> float:
	var base = (size / 20000.0) * 0.3
	var month = (day / 30) % 12
	if month in [0, 1, 11]:    # Winter cluster spike check
		base *= 1.5
	return base

# ────────────────────────────────────────────────
# Inspection (still useful for debugging)
# ────────────────────────────────────────────────

func inspect_hive() -> void:
	print("=== HIVE INSPECTION ===")
	print("Population: %d bees" % colony_population)
	print("Queen: %s (Age: %d days)" % ["Present" if queen else "Missing", queen_age])
	print("Eggs: %d | Nurses: %d | Workers: %d | Drones: %d" % [eggs, nurseBee, workerBee, drone])
	print("Honey: %.1f lbs | Pollen: %.1f lbs" % [honey_stores, pollen_stores])
	print("Mite Level: %.1f | Survival Rate: %.1f%%" % [mites, survival_rate * 100.0])
	print("=====================")

func _on_area_2d_input_event(_viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		inspect_hive()
