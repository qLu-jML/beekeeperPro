extends CharacterBody2D

var player_honey: float = 0.0
var facing_direction: Vector2 = Vector2.DOWN
var last_x_dir: float = 1.0

# Movement variables
@export var speed: float = 200.0
@export var friction: float = 500.0

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
				var target_pos = global_position + (facing_direction * 16.0)
				var map_coords = tilemap.local_to_map(tilemap.to_local(target_pos))
				tilemap.set_cell(1, map_coords, 0, Vector2i(1, 3))
		elif event.keycode == KEY_F:
			if tilemap:
				var target_pos = global_position + (facing_direction * 16.0)
				var map_coords = tilemap.local_to_map(tilemap.to_local(target_pos))
				
				# Determine if ground is dirt (Layer 1 has a tile)
				if tilemap.get_cell_source_id(1, map_coords) != -1:
					var new_flower = FLOWER_SCENE.instantiate()
					new_flower.global_position = tilemap.to_global(tilemap.map_to_local(map_coords))
					get_parent().add_child(new_flower)
				else:
					print("You must plant seeds on tilled dirt!")
		elif event.keycode == KEY_E:
			if tilemap:
				var target_pos = global_position + (facing_direction * 16.0)
				var map_coords = tilemap.local_to_map(tilemap.to_local(target_pos))
				var target_global = tilemap.to_global(tilemap.map_to_local(map_coords))
				
				var hives = get_tree().get_nodes_in_group("hive")
				var harvested = false
				for hive in hives:
					if hive.global_position.distance_to(target_global) < 16.0:
						if hive.has_method("harvest_honey"):
							var amount = hive.harvest_honey()
							if amount > 0:
								player_honey += amount
								print("Harvested %.1f lbs of honey!" % amount)
								
								# UI is a sibling of World, so it's two steps up from Player
								var hud = get_node_or_null("../../UI")
								if hud and hud.has_method("update_player_inventory"):
									hud.update_player_inventory(player_honey)
								else:
									print("Could not find HUD UI node!")
								harvested = true
								break
				if not harvested:
					print("No harvestable hive there!")

func _ready():
	pass

func _physics_process(delta):
	# Get input direction
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_vector = input_vector.normalized()
	
	# Apply movement
	if input_vector != Vector2.ZERO:
		velocity = input_vector * speed
		play_animation(input_vector)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		if animated_sprite:
			animated_sprite.stop()
	
	# Move the character (Godot 4 syntax - no parameters)
	move_and_slide()

func play_animation(direction: Vector2):
	if not animated_sprite:
		return
	
	if direction.x != 0:
		last_x_dir = sign(direction.x)
	
	# Determine which animation to play based on direction
	if abs(direction.x) > abs(direction.y):
		if direction.x > 0:
			animated_sprite.play("walk_right")
			facing_direction = Vector2(1, 0)
		else:
			animated_sprite.play("walk_left")
			facing_direction = Vector2(-1, 0)
	else:
		if direction.y > 0:
			animated_sprite.play("walk_down")
			facing_direction = Vector2(last_x_dir, 1)
		else:
			animated_sprite.play("walk_up")
			facing_direction = Vector2(last_x_dir, -1)
