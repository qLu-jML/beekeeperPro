extends Node2D
class_name Flower

enum GrowthStage { SEED, SPROUT, BLOOM }

@export var flower_name: String = "Daisy"
@export var days_to_full_bloom: int = 5               # can be different per flower type later
@export var nectar_value_when_bloomed: float = 2.0    # base nectar per day when blooming

var current_stage: GrowthStage = GrowthStage.SEED
var days_since_planted: int = 0

func _ready() -> void:
	update_appearance()

func advance_day() -> void:
	days_since_planted += 1
	
	if days_since_planted >= days_to_full_bloom:
		current_stage = GrowthStage.BLOOM
	elif days_since_planted >= ceil(days_to_full_bloom / 2.0):
		current_stage = GrowthStage.SPROUT
	else:
		current_stage = GrowthStage.SEED
	
	update_appearance()
	print("[Flower %s] Day %d/%d → %s" % [flower_name, days_since_planted, days_to_full_bloom, current_stage])

func update_appearance() -> void:
	var color_rect = $Placeholder as ColorRect
	var label = $StageLabel as Label
	
	match current_stage:
		GrowthStage.SEED:
			color_rect.color = Color(0.55, 0.35, 0.15)  # brown dirt/seed
			label.text = "Seed"
		GrowthStage.SPROUT:
			color_rect.color = Color(0.4, 0.8, 0.4)      # green shoot
			label.text = "Sprout"
		GrowthStage.BLOOM:
			color_rect.color = Color(1.0, 0.8, 0.9)      # pink/purple flower
			label.text = "Bloom!"

	# Later replace modulate with real textures:
	# $Visual.texture = preload("res://sprites/flowers/daisy_bloom.png")
