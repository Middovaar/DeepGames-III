extends CharacterBody2D
@onready var timer: Timer = $Timer
var input_listen: bool = false

@export var speed : float = 10000
@export var input_time: float = 3
@export var player: Area2D

func _ready() -> void:
	SpotlightManager.MOVE = true

func _process(delta: float) -> void:
	# Move Spotlight to the left if passed
	if SpotlightManager.MOVE: velocity.x = -(speed * delta)
	else: velocity.x = 0
	move_and_slide()
	
	#region - Looping spotlights
	# Check if spotlight is out of bounds
	# and reset position if so
	#if position < SpotlightManager.VECTOR_DESPAWN: 
	#	position = SpotlightManager.VECTOR_SPAWN
	#endregion

func _on_area_entered(area: Area2D) -> void:
	SpotlightManager.MOVE = false
	input_listen = true
	timer.start(input_time)

func on_input_timeout() -> void:
	# What happens if player fails event
	SpotlightManager.MOVE = true
	input_listen = false
	print_debug("Failed Check")
