extends Node

signal pressure_changed(value: float, maximum: float)
signal pressure_failed

@export var player: Node2D
@export var pressure_bar: Control

@export_range(1.0, 1000.0, 1.0) var max_pressure: float = 100.0
@export var penalty_per_spotlight: float = 30.0

var pressure: float = 0.0
var failed: bool = false
var player_head: Area2D

# Remember which spotlights have already caused a penalty.
var penalized_spotlights: Dictionary = {}


func _ready() -> void:
	if player == null or pressure_bar == null:
		push_error("Assign Player and Pressure Bar in the Inspector.")
		set_physics_process(false)
		return

	player_head = player.get_node("Head") as Area2D

	if not pressure_bar.is_node_ready():
		await pressure_bar.ready

	pressure_changed.connect(
		Callable(pressure_bar, "_RecieveScore")
	)
	player.connect("expression_changed", _on_expression_changed)

	pressure_changed.emit(pressure, max_pressure)
	print("Pressure: ", pressure, " / ", max_pressure)


func _physics_process(_delta: float) -> void:
	var emotion: String = player.get("current_emotion")
	_check_spotlights(emotion)


func _on_expression_changed(emotion: String) -> void:
	# Also check immediately when the player changes expression.
	_check_spotlights(emotion)


func _check_spotlights(emotion: String) -> void:
	if failed or emotion == "smile":
		return

	for area: Area2D in player_head.get_overlapping_areas():
		if not area.get_collision_layer_value(1):
			continue

		# SpotlightArea is a child of its Spotlight node.
		var spotlight_id: int = area.get_parent().get_instance_id()

		if penalized_spotlights.has(spotlight_id):
			continue

		# Mark this spotlight before applying its one-time penalty.
		penalized_spotlights[spotlight_id] = true
		_add_penalty()

		if failed:
			return


func _add_penalty() -> void:
	pressure = minf(
		pressure + penalty_per_spotlight,
		max_pressure
	)
	pressure_changed.emit(pressure, max_pressure)
	print("Pressure: ", pressure, " / ", max_pressure)

	if pressure >= max_pressure:
		failed = true
		pressure_failed.emit()
		print("Pressure limit reached")
		get_tree().paused = true
