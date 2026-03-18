extends CharacterBody2D

var speed = 200
var player_velocity = Vector2.ZERO

func _ready():
	$PlayerAnimatedSprite.play("idle")  # Ensure this matches your animation name

func _input(event):
	var input_vector = Vector2.ZERO
	if event.is_action_pressed("move_right"):
		input_vector.x += 1
	elif event.is_action_pressed("move_left"):
		input_vector.x -= 1
	elif event.is_action_pressed("move_down"):
		input_vector.y += 1
	elif event.is_action_pressed("move_up"):
		input_vector.y -= 1
	
	player_velocity = input_vector.normalized() * speed

func _physics_process(delta):
	move_and_slide(player_velocity)
