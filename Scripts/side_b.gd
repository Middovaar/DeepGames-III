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
# Seconds between consecutive monster spawns.
@export_range(0.5, 10.0, 0.1)
var spawn_interval: float = 3.0

var player: Node2D
var inventory: Node

var health: int = 100
var running: bool = false
var response_time: float = 0.0

var encounter_queue: Array[String] = []
var current_monster: EmotionMonster
# Track encounters that have not been resolved.
var active_monsters: Array[EmotionMonster] = []

@onready var monsters: Node2D = $Monsters
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var health_bar: ProgressBar = $HUD/HealthBar

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
	_update_health_display()
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
	_spawn_sequence()

func _spawn_next() -> void:
	if not running or encounter_queue.is_empty():
		return

	var emotion: String = encounter_queue.pop_front()
	var monster := MONSTER_SCENE.instantiate() as EmotionMonster

	monster.required_emotion = emotion
	monster.encounter_resolved.connect(_on_encounter_resolved)

	active_monsters.append(monster)
	monsters.add_child(monster)

	monster.global_position = spawn_point.global_position
	monster.start()

func _physics_process(delta: float) -> void:
	if not running:
		return

	_select_response_target()

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
	if not running or not active_monsters.has(monster):
		return

	active_monsters.erase(monster)

	if monster == current_monster:
		current_monster = null
		_reset_response()

	if not success:
		health = maxi(health - mistake_damage, 0)
		_update_health_display()
		print("Side B health: ", health)

		if health <= 0:
			running = false
			print("Side B failed")
			side_b_finished.emit(false)
			get_tree().paused = true
			return

	# Finish after all planned encounters have been resolved.
	if encounter_queue.is_empty() and active_monsters.is_empty():
		running = false
		_reset_response()

		print("Side B survived")
		side_b_finished.emit(true)
func _update_health_display() -> void:
	# Update the remaining health.
	health_bar.value = health
func _spawn_sequence() -> void:
	while running and not encounter_queue.is_empty():
		_spawn_next()

		if encounter_queue.is_empty():
			return

		# Pause the countdown when the game is paused.
		await get_tree().create_timer(
			spawn_interval,
			false
		).timeout

func _select_response_target() -> void:
	var next_monster: EmotionMonster = null

	# Prioritize the earliest unresolved monster in range.
	for monster in active_monsters:
		if not is_instance_valid(monster):
			continue

		if monster.in_response_range and not monster.resolved:
			next_monster = monster
			break

	if next_monster != current_monster:
		current_monster = next_monster
		_reset_response()
