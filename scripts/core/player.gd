extends CharacterBody2D

enum Mode { NORMAL = 0, TILL = 1, PLANT = 2, HIVE = 3 }
var current_mode: Mode = Mode.NORMAL
var mode_label: Label = null

var facing_direction: Vector2 = Vector2.DOWN

const INVENTORY_SIZE = 20
var inventory: Array = []

func get_max_stack(item_name: String) -> int:
	match item_name:
		"honey": return 100
		_: return 20

func get_total_honey() -> int:
	var total := 0
	for slot in inventory:
		if slot != null and slot["item"] == "honey":
			total += slot["count"]
	return total

func _ready():
	inventory.resize(INVENTORY_SIZE)
	inventory.fill(null)
	add_item("seeds", 5)

	mode_label = Label.new()
	mode_label.name = "ModeLabel"
	mode_label.add_theme_font_size_override("font_size", 8)
	mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mode_label.custom_minimum_size = Vector2(64, 10)
	mode_label.position = Vector2(-32, -28)
	mode_label.z_index = 10
	add_child(mode_label)
	_update_mode_label()

func _set_mode(new_mode: Mode) -> void:
	current_mode = Mode.NORMAL if current_mode == new_mode else new_mode
	_update_mode_label()

func _update_mode_label() -> void:
	if not mode_label:
		return
	var labels := ["Normal", "Till", "Plant", "Hive"]
	mode_label.text = "[%s]" % labels[current_mode]

func update_hud_inventory() -> void:
	var hud = get_node_or_null("../../UI")
	if hud and hud.has_method("update_player_inventory"):
		hud.update_player_inventory(get_total_honey(), inventory)

func add_item(item_name: String, amount: int) -> int:
	var stack_max := get_max_stack(item_name)
	for i in range(INVENTORY_SIZE):
		if inventory[i] != null and inventory[i]["item"] == item_name:
			var space = stack_max - inventory[i]["count"]
			if space > 0:
				var add = min(space, amount)
				inventory[i]["count"] += add
				amount -= add
				if amount <= 0:
					update_hud_inventory()
					return 0
	if amount > 0:
		for i in range(INVENTORY_SIZE):
			if inventory[i] == null:
				var add = min(stack_max, amount)
				inventory[i] = {"item": item_name, "count": add}
				amount -= add
				if amount <= 0:
					update_hud_inventory()
					return 0
	update_hud_inventory()
	return amount 

func consume_item(item_name: String, amount: int) -> bool:
	var total = 0
	for i in range(INVENTORY_SIZE):
		if inventory[i] != null and inventory[i]["item"] == item_name:
			total += inventory[i]["count"]
	if total < amount:
		return false
	for i in range(INVENTORY_SIZE):
		if inventory[i] != null and inventory[i]["item"] == item_name:
			if inventory[i]["count"] >= amount:
				inventory[i]["count"] -= amount
				if inventory[i]["count"] == 0:
					inventory[i] = null
				amount = 0
				break
			else:
				amount -= inventory[i]["count"]
				inventory[i] = null
	update_hud_inventory()
	return true

# Movement variables (Snappy farm sim feel)
@export var speed: float = 120.0

# Animation
@onready var animated_sprite = $AnimatedSprite2D

const HIVE_SCENE = preload("res://scenes/hive.tscn")
const FLOWER_SCENE = preload("res://scenes/flowers/flowers.tscn")

@onready var tilemap: TileMap = get_node_or_null("../TileMap")
@onready var zone_manager = get_node_or_null("../ZoneManager")
@onready var grid_overlay = get_node_or_null("../GridOverlay")

func _toggle_grid() -> void:
	var overlay = grid_overlay if grid_overlay else get_node_or_null("../GridOverlay")
	if overlay:
		overlay.show_grid = not overlay.show_grid

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_G: _toggle_grid()
		KEY_H: _set_mode(Mode.HIVE)
		KEY_T: _set_mode(Mode.TILL)
		KEY_F: _set_mode(Mode.PLANT)
		KEY_0:
			current_mode = Mode.NORMAL
			_update_mode_label()
		KEY_E: _perform_action()
		KEY_7:
			if tilemap and zone_manager:
				zone_manager.set_flower(get_target_tile_coords(tilemap))
		KEY_8:
			if tilemap and zone_manager:
				zone_manager.set_apiary(get_target_tile_coords(tilemap))
		KEY_9:
			if tilemap and zone_manager:
				zone_manager.clear_tile(get_target_tile_coords(tilemap))

func _perform_action() -> void:
	match current_mode:
		Mode.NORMAL: _action_interact()
		Mode.TILL:   _action_till()
		Mode.PLANT:  _action_plant()
		Mode.HIVE:   _action_place_hive()

func _action_till() -> void:
	if not tilemap:
		return
	var map_coords = get_target_tile_coords(tilemap)
	if zone_manager and zone_manager.is_flower_zone(map_coords):
		tilemap.set_cell(1, map_coords, 0, Vector2i(1, 3))
		_set_mode(Mode.NORMAL)
	else:
		print("You can only till soil inside the flower field!")

func _action_plant() -> void:
	if not tilemap:
		return
	var map_coords = get_target_tile_coords(tilemap)
	if tilemap.get_cell_source_id(1, map_coords) != -1:
		if consume_item("seeds", 1):
			var new_flower = FLOWER_SCENE.instantiate()
			new_flower.global_position = tilemap.to_global(tilemap.map_to_local(map_coords))
			get_parent().add_child(new_flower)
			update_hud_inventory()
			_set_mode(Mode.NORMAL)
		else:
			print("Not enough seeds!")
	else:
		print("You must plant seeds on tilled dirt!")

func _hive_placement_valid(map_coords: Vector2i) -> bool:
	for h in get_tree().get_nodes_in_group("hive"):
		var hive_tile: Vector2i
		if h.has_meta("tile_coords"):
			hive_tile = h.get_meta("tile_coords")
		else:
			hive_tile = tilemap.local_to_map(tilemap.to_local(h.global_position))
		if maxi(abs(map_coords.x - hive_tile.x), abs(map_coords.y - hive_tile.y)) <= 2:
			return false
	return true

func _action_place_hive() -> void:
	if not tilemap:
		return
	var map_coords = get_target_tile_coords(tilemap)
	if zone_manager and not zone_manager.is_apiary_zone(map_coords):
		print("Hives can only be placed inside the apiary!")
		return
	if not _hive_placement_valid(map_coords):
		print("Too close to another hive! Hives need a 5x5 space.")
		return
	var new_hive = HIVE_SCENE.instantiate()
	get_parent().add_child(new_hive)
	new_hive.global_position = tilemap.to_global(tilemap.map_to_local(map_coords))
	new_hive.set_meta("tile_coords", map_coords)
	_set_mode(Mode.NORMAL)

func _closest_in_group(group: String, max_dist: float) -> Node:
	var best: Node = null
	var best_dist := max_dist
	for node in get_tree().get_nodes_in_group(group):
		var d := node.global_position.distance_to(global_position)
		if d < best_dist:
			best_dist = d
			best = node
	return best

func _action_interact() -> void:
	var harvested := false
	var hives_in_group := get_tree().get_nodes_in_group("hive")
	print("E pressed — hive group size: %d | player pos: %s" % [hives_in_group.size(), str(global_position)])
	for h in hives_in_group:
		print("  hive: %s  dist: %.1f" % [str(h.global_position), h.global_position.distance_to(global_position)])

	var nearby_hive = _closest_in_group("hive", 64.0)
	if nearby_hive and nearby_hive.has_method("harvest_honey"):
		var amount: int = roundi(nearby_hive.harvest_honey())
		if amount > 0:
			var leftover: int = add_item("honey", amount)
			if leftover > 0:
				print("Inventory full! Lost %d lbs of honey." % leftover)
			else:
				print("Harvested %d lbs of honey!" % amount)
			update_hud_inventory()
			harvested = true

	if not harvested:
		var nearby_flower = _closest_in_group("flowers", 32.0)
		if nearby_flower and nearby_flower.has_method("harvest_seeds"):
			var seeds: int = nearby_flower.harvest_seeds()
			if seeds > 0:
				add_item("seeds", seeds)
				print("Harvested %d seeds!" % seeds)
				update_hud_inventory()
				harvested = true

	if not harvested:
		print("Nothing nearby to interact with!")

func get_target_tile_coords(map: TileMap) -> Vector2i:
	var player_feet_local = map.to_local(global_position)
	var current_tile = map.local_to_map(player_feet_local)
	return current_tile + Vector2i(facing_direction)

var _last_painted_tile: Vector2i = Vector2i(-9999, -9999)

func _get_current_tile() -> Vector2i:
	if not tilemap:
		return Vector2i(-9999, -9999)
	return tilemap.local_to_map(tilemap.to_local(global_position))

func _apply_zone_paint() -> void:
	if not tilemap or not zone_manager:
		return
	var tile = _get_current_tile()
	if tile == _last_painted_tile:
		return
	_last_painted_tile = tile
	if Input.is_key_pressed(KEY_7):
		zone_manager.set_flower(tile)
	elif Input.is_key_pressed(KEY_8):
		zone_manager.set_apiary(tile)
	elif Input.is_key_pressed(KEY_9):
		zone_manager.clear_tile(tile)

func _physics_process(delta):
	# Get input direction
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")

	# Apply snappy non-sliding movement
	if input_vector != Vector2.ZERO:
		input_vector = input_vector.normalized()
		velocity = input_vector * speed
		play_animation(input_vector)
	else:
		velocity = Vector2.ZERO
		if animated_sprite:
			animated_sprite.stop()

	move_and_slide()
	_apply_zone_paint()

func play_animation(direction: Vector2):
	if not animated_sprite:
		return
		
	# Determine strictly 4-directional facing
	if abs(direction.x) > abs(direction.y):
		if direction.x > 0:
			animated_sprite.play("walk_right")
			facing_direction = Vector2.RIGHT
		else:
			animated_sprite.play("walk_left")
			facing_direction = Vector2.LEFT
	else:
		if direction.y > 0:
			animated_sprite.play("walk_down")
			facing_direction = Vector2.DOWN
		else:
			animated_sprite.play("walk_up")
			facing_direction = Vector2.UP
