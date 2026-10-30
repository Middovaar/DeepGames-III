extends Node2D

signal side_b_finished(success: bool)

const MONSTER_SCENE: PackedScene = preload(
	"res://Scenes/monster.tscn"
)

const RESPONSE_ACTIONS: Dictionary = {
	"sad": "emoji_sad",
	"shy": "emoji_shy",
	"angry": "emoji_angry",
}

@export_range(0.1, 2.0, 0.1)
var response_duration: float = 0.6

@export var mistake_damage: int = 35

var player: Node2D
var inventory: Node

var health: int = 100
var running: bool = false
var response_time: float = 0.0

var encounter_queue: Array[String] = []
var current_monster: EmotionMonster

@onready var monsters: Node2D = $Monsters
@onready var spawn_point: Marker2D = $SpawnPoint


func start(
	player_node: Node2D,
	inventory_node: Node,
	emotions: Array[String]
) -> void:
	if running:
		return

	player = player_node
	inventory = inventory_node

	if player == null or inventory == null:
		push_error("Side B requires Player and EmotionInventory.")
		return

	encounter_queue.assign(emotions)
	health = 100
	running = true

	player.call("set_collection_enabled", false)

	if not player.is_connected(
		"expression_changed",
		_on_expression_changed
	):
		player.connect(
			"expression_changed",
			_on_expression_changed
		)

	_reset_response()

	print("Side B health: ", health)
	_spawn_next()


func _spawn_next() -> void:
	if not running:
		return

	if encounter_queue.is_empty():
		running = false
		_reset_response()

		print("Side B survived")
		side_b_finished.emit(true)
		return

	var emotion: String = encounter_queue.pop_front()
	var monster := MONSTER_SCENE.instantiate() as EmotionMonster

	monster.required_emotion = emotion
	monster.encounter_resolved.connect(_on_encounter_resolved)

	current_monster = monster
	monsters.add_child(monster)

	monster.global_position = spawn_point.global_position
	monster.start()


func _physics_process(delta: float) -> void:
	if not running:
		return

	if not is_instance_valid(current_monster):
		_reset_response()
		return

	if not current_monster.in_response_range:
		_reset_response()
		return

	var emotion: String = current_monster.required_emotion
	var action: String = RESPONSE_ACTIONS[emotion]
	var current_emotion: String = player.get("current_emotion")
	var counts: Dictionary = inventory.get("counts")

	# Require matching input and available inventory.
	if (
		current_emotion != emotion
		or not Input.is_action_pressed(action)
		or int(counts.get(emotion, 0)) <= 0
	):
		_reset_response(true)
		return

	response_time = minf(
		response_time + delta,
		response_duration
	)

	player.call(
		"set_response_progress",
		response_time / response_duration,
		true
	)

	if response_time >= response_duration:
		var consumed: bool = inventory.call(
			"try_consume",
			emotion
		)

		if consumed:
			current_monster.resolve(true)
		else:
			_reset_response(true)


func _input(event: InputEvent) -> void:
	if not running or not is_instance_valid(current_monster):
		return

	var action: String = RESPONSE_ACTIONS[
		current_monster.required_emotion
	]

	# Reset even when a release and another press occur between frames.
	if event.is_action_released(action):
		_reset_response(current_monster.in_response_range)


func _on_expression_changed(_emotion: String) -> void:
	response_time = 0.0


func _reset_response(show_bar: bool = false) -> void:
	response_time = 0.0
	player.call("set_response_progress", 0.0, show_bar)


func _on_encounter_resolved(
	monster: EmotionMonster,
	success: bool
) -> void:
	if monster != current_monster:
		return

	current_monster = null
	_reset_response()

	if not success:
		health = maxi(health - mistake_damage, 0)
		print("Side B health: ", health)

		if health <= 0:
			running = false
			print("Side B failed")
			side_b_finished.emit(false)

			# Pause until the final failure UI is available.
			get_tree().paused = true
			return

	# Spawn outside the physics collision callback.
	call_deferred("_spawn_next")
