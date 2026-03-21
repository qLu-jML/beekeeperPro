extends CharacterBody2D

var player_honey: float = 0.0
var facing_direction: Vector2 = Vector2.DOWN

const INVENTORY_SIZE = 20
const MAX_STACK = 20
var inventory: Array = []

func _ready():
	inventory.resize(INVENTORY_SIZE)
	inventory.fill(null)
	add_item("seeds", 5)

func update_hud_inventory() -> void:
	var hud = get_node_or_null("../../UI")
	if hud and hud.has_method("update_player_inventory"):
		hud.update_player_inventory(player_honey, inventory)

func add_item(item_name: String, amount: int) -> int:
	for i in range(INVENTORY_SIZE):
		if inventory[i] != null and inventory[i]["item"] == item_name:
			var space = MAX_STACK - inventory[i]["count"]
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
				var add = min(MAX_STACK, amount)
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

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_H:
			var new_hive = HIVE_SCENE.instantiate()
			new_hive.global_position = global_position
			get_parent().add_child(new_hive)
		elif event.keycode == KEY_T:
			if tilemap:
				var map_coords = get_target_tile_coords(tilemap)
				tilemap.set_cell(1, map_coords, 0, Vector2i(1, 3))
		elif event.keycode == KEY_F:
			if tilemap:
				var map_coords = get_target_tile_coords(tilemap)
				
				# Determine if ground is dirt (Layer 1 has a tile)
				if tilemap.get_cell_source_id(1, map_coords) != -1:
					if consume_item("seeds", 1):
						var new_flower = FLOWER_SCENE.instantiate()
						new_flower.global_position = tilemap.to_global(tilemap.map_to_local(map_coords))
						get_parent().add_child(new_flower)
						update_hud_inventory()
					else:
						print("Not enough seeds!")
				else:
					print("You must plant seeds on tilled dirt!")
		elif event.keycode == KEY_E:
			if tilemap:
				var map_coords = get_target_tile_coords(tilemap)
				var target_global = tilemap.to_global(tilemap.map_to_local(map_coords))
				
				var hives = get_tree().get_nodes_in_group("hive")
				var harvested = false
				for hive in hives:
					# Large 32px tolerance guarantees overlapping any part of the 32x32 hive sprite triggers success
					if hive.global_position.distance_to(target_global) < 32.0:
						if hive.has_method("harvest_honey"):
							var amount = hive.harvest_honey()
							if amount > 0:
								player_honey += amount
								print("Harvested %.1f lbs of honey!" % amount)
								update_hud_inventory()
								harvested = true
								break
								
				# Check for harvestable flowers
				var flowers = get_tree().get_nodes_in_group("flowers")
				if not harvested:
					for flower in flowers:
						if flower.global_position.distance_to(target_global) < 24.0:
							if flower.has_method("harvest_seeds"):
								var seeds = flower.harvest_seeds()
								if seeds > 0:
									var leftover = add_item("seeds", seeds)
									print("Harvested %d seeds! (Leftover: %d)" % [seeds, leftover])
									update_hud_inventory()
									harvested = true
									break
									
				if not harvested:
					print("Nothing to interact with there!")

func get_target_tile_coords(map: TileMap) -> Vector2i:
	var player_feet_local = map.to_local(global_position)
	var current_tile = map.local_to_map(player_feet_local)
	return current_tile + Vector2i(facing_direction)

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
