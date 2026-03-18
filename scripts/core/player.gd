extends CharacterBody2D  # Change to CharacterBody2D in Godot 4.0

# Speed variable to control movement speed
var speed = 200
var player_velocity = Vector2.ZERO  # Rename this variable

func _ready():
	$PlayerAnimatedSprite.play("Idle")  # Start with Idle animation

func _process(delta):
	player_velocity = Vector2.ZERO  # Reset player_velocity each frame

	# Input handling for movement
	if Input.is_action_pressed("ui_right"):
		player_velocity.x += 1
	if Input.is_action_pressed("ui_left"):
		player_velocity.x -= 1
	if Input.is_action_pressed("ui_down"):
		player_velocity.y += 1
	if Input.is_action_pressed("ui_up"):
		player_velocity.y -= 1

	# Normalize the velocity to maintain consistent speed
	player_velocity = player_velocity.normalized() * speed

	# Move the player and slide along surfaces
	move_and_slide()  # No arguments needed
