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
		print("Warning: Single Hive not found at ../World/Hive. Operating in multi-hive mode.")
	
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
	
	if hive:
		hive.advance_day()
	else:
		var world_node = get_node_or_null("../World")
		if world_node:
			for child in world_node.get_children():
				if "Hive" in child.name and child.has_method("advance_day"):
					child.advance_day()
	
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
	var current_hive = hive
	
	if not current_hive:
		var world_node = get_node_or_null("../World")
		if world_node:
			for child in world_node.get_children():
				if "Hive" in child.name:
					current_hive = child
					break
	
	if current_hive:
		print("Updating UI labels - day: ", current_hive.days_elapsed)
		
		if day_label:
			day_label.text = "Day: %d - %s" % [current_hive.days_elapsed, get_season_name(current_hive)]
		
		if resource_label:
			resource_label.text = ""
	else:
		if day_label:
			day_label.text = "Day: ?"
		if resource_label:
			resource_label.text = ""

@onready var inventory_menu: ColorRect = get_node_or_null("InventoryMenu")
@onready var inventory_label: Label = get_node_or_null("InventoryMenu/PlayerInventoryLabel")

@onready var controls_label: Label = get_node_or_null("ControlsLabel")

var menu_open: bool = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_O:
			toggle_menu()

func toggle_menu() -> void:
	menu_open = not menu_open
	if inventory_menu:
		inventory_menu.visible = menu_open
		
	var target_vis = not menu_open
	if day_label: day_label.visible = target_vis
	if resource_label: resource_label.visible = target_vis
	if controls_label: controls_label.visible = target_vis
	if next_day_button: next_day_button.visible = target_vis

func update_player_inventory(amount: float) -> void:
	if inventory_label:
		inventory_label.text = "Honey Storage: %.1f lbs" % amount

func get_season_name(target_hive = null) -> String:
	if not target_hive:
		target_hive = hive
	if not target_hive:
		return "Unknown"
	
	var day_in_year = target_hive.days_elapsed % 120
	if day_in_year < 30:
		return "Spring"
	elif day_in_year < 60:
		return "Summer"
	elif day_in_year < 90:
		return "Autumn"
	else:
		return "Winter"
