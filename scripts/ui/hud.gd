extends CanvasLayer

@onready var hive = get_node_or_null("../World/Hive")
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
	
	_update_ui_labels()
	_setup_inventory()
	
	# Explicitly synchronize initial items from player because hud layout initializes slightly after player
	var player = get_node_or_null("../World/player")
	if player and player.has_method("update_hud_inventory"):
		player.update_hud_inventory()

func _setup_inventory():
	if not inventory_menu:
		var panel_width = 170
		var panel_height = 50

		var menu_panel = ColorRect.new()
		menu_panel.name = "InventoryMenu"
		menu_panel.color = Color(0.05, 0.05, 0.05, 0.9)
		menu_panel.size = Vector2(panel_width, panel_height)
		menu_panel.position = Vector2(320 / 2.0 - panel_width / 2.0, 180 / 2.0 - panel_height / 2.0)
		menu_panel.hide()
		add_child(menu_panel)
		inventory_menu = menu_panel

		var title = Label.new()
		title.name = "PlayerInventoryLabel"
		title.text = "Inventory"
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", 8)
		title.size = Vector2(panel_width, 12)
		title.position = Vector2(0, 2)
		inventory_menu.add_child(title)
		inventory_label = title

		var grid = GridContainer.new()
		grid.name = "GridContainer"
		grid.columns = 10
		grid.add_theme_constant_override("h_separation", 0)
		grid.add_theme_constant_override("v_separation", 0)
		grid.position = Vector2((panel_width - 160) / 2.0, (panel_height - 32) / 2.0 + 4)
		inventory_menu.add_child(grid)
		inventory_grid = grid

	# Always populate slots if the grid exists but is empty
	if inventory_grid and inventory_grid.get_child_count() == 0:
		for i in range(20):
			var slot = ColorRect.new()
			slot.custom_minimum_size = Vector2(14, 14)
			slot.color = Color(0.2, 0.2, 0.2, 1.0)

			var border = Panel.new()
			border.set_anchors_preset(Control.PRESET_FULL_RECT)
			border.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0, 0, 0, 0)
			style.draw_center = false
			style.border_color = Color(0.8, 0.8, 0.8, 1.0)
			style.border_width_bottom = 1
			style.border_width_top = 1
			style.border_width_left = 1
			style.border_width_right = 1
			border.add_theme_stylebox_override("panel", style)
			slot.add_child(border)

			var amount_label = Label.new()
			amount_label.text = ""
			amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			amount_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
			amount_label.set_anchors_preset(Control.PRESET_FULL_RECT)
			amount_label.add_theme_font_size_override("font_size", 6)
			slot.add_child(amount_label)

			var name_label = Label.new()
			name_label.text = ""
			name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			name_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
			name_label.set_anchors_preset(Control.PRESET_FULL_RECT)
			name_label.add_theme_font_size_override("font_size", 6)
			slot.add_child(name_label)

			inventory_grid.add_child(slot)
			slots.append(slot)


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
	
	var world_node_ref = get_node_or_null("../World")
	var global_day = 0
	if hive:
		global_day = hive.days_elapsed
	elif world_node_ref:
		for c in world_node_ref.get_children():
			if "Hive" in c.name:
				global_day = c.days_elapsed
				break

	var flowers = get_tree().get_nodes_in_group("flowers")
	if flowers.size() > 0:
		for flower in flowers:
			if flower.has_method("advance_day_with_global"):
				flower.advance_day_with_global(global_day)
			elif flower.has_method("advance_day"):
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
@onready var inventory_grid: GridContainer = get_node_or_null("InventoryMenu/GridContainer")
var slots: Array = []

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

func update_player_inventory(honey: float, inv_array: Array = []) -> void:
	if inventory_label:
		inventory_label.text = "Honey Storage: %.1f lbs" % honey
		
	for i in range(slots.size()):
		if i < inv_array.size() and inv_array[i] != null:
			var item = inv_array[i]
			if item["item"] == "seeds":
				slots[i].get_child(1).text = "x" + str(item["count"])
				slots[i].get_child(2).text = "Seeds"
				slots[i].color = Color(0.3, 0.5, 0.3, 1.0)
		else:
			slots[i].get_child(1).text = ""
			slots[i].get_child(2).text = ""
			slots[i].color = Color(0.2, 0.2, 0.2, 1.0)

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
