extends CharacterBody2D

# Movement variables
@export var speed: float = 200.0
@export var friction: float = 500.0

# Animation
@onready var animated_sprite = $AnimatedSprite2D

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
	
	# Determine which animation to play based on direction
	if abs(direction.x) > abs(direction.y):
		if direction.x > 0:
			animated_sprite.play("walk_right")
		else:
			animated_sprite.play("walk_left")
	else:
		if direction.y > 0:
			animated_sprite.play("walk_down")
		else:
			animated_sprite.play("walk_up")
