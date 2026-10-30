extends Node2D

const SIDE_B_SCENE: PackedScene = preload(
	"res://Scenes/side_b.tscn"
)

const EMOTIONS: Array[String] = ["sad", "shy", "angry"]

enum Phase {
	SIDE_A,
	TRANSITION,
	SIDE_B,
	FINISHED,
}

var phase: Phase = Phase.SIDE_A
var detection_ready: bool = false
var in_gap: bool = false
var gap_count: int = 0

var spotlight_ids: Dictionary = {}
var seen_spotlights: Dictionary = {}

@onready var player: Node2D = $Player
@onready var head: Area2D = $Player/Head
@onready var inventory: Node = $EmotionInventory
@onready var spotlights: Node2D = $Spotlights
@onready var pressure_controller: Node = $PressureController
@onready var pressure_display: Control = $HUD/PressureBar


func _ready() -> void:
	player.call("set_collection_enabled", false)

	# Register the spotlights included in this round.
	for spotlight in spotlights.get_children():
		var area := spotlight.get_node_or_null(
			"SpotlightArea"
		) as Area2D

		if area != null:
			spotlight_ids[area.get_instance_id()] = true

	if spotlight_ids.is_empty():
		push_error("Side A requires at least one spotlight.")
		set_physics_process(false)
		return

	# Wait for physics overlap information to become available.
	await get_tree().physics_frame
	await get_tree().physics_frame

	detection_ready = true
	player.call("set_collection_enabled", true)

	print("Side A started")


func _physics_process(_delta: float) -> void:
	if not detection_ready or phase != Phase.SIDE_A:
		return

	var is_watched: bool = false

	for area: Area2D in head.get_overlapping_areas():
		var area_id: int = area.get_instance_id()

		if spotlight_ids.has(area_id):
			seen_spotlights[area_id] = true
			is_watched = true

	if is_watched:
		in_gap = false
		return

	# End Side A after every spotlight has passed the player.
	if seen_spotlights.size() == spotlight_ids.size():
		phase = Phase.TRANSITION

		player.call("set_collection_enabled", false)
		pressure_controller.set("enabled", false)

		call_deferred("_start_side_b")
		return

	# Count the opening gap and each gap between spotlights.
	if not in_gap:
		in_gap = true
		gap_count += 1

		print("Collection gap: ", gap_count)


func _build_encounters() -> Array[String]:
	var encounters: Array[String] = []
	var missing_emotions: Array[String] = []
	var counts: Dictionary = inventory.get("counts")

	# Include one matching monster for every collected emoji.
	for emotion in EMOTIONS:
		var quantity: int = int(counts.get(emotion, 0))

		if quantity == 0:
			missing_emotions.append(emotion)

		for _index in range(quantity):
			encounters.append(emotion)

	# Reject inconsistent inventory instead of discarding stock.
	if encounters.size() > gap_count:
		return []

	# Use all emotions if every type has already been collected.
	if missing_emotions.is_empty():
		missing_emotions.assign(EMOTIONS)

	# Fill remaining slots using uncollected emotion types.
	while encounters.size() < gap_count:
		var index: int = randi_range(
			0,
			missing_emotions.size() - 1
		)

		encounters.append(missing_emotions[index])

	encounters.shuffle()
	return encounters


func _start_side_b() -> void:
	var encounters: Array[String] = _build_encounters()

	if encounters.size() != gap_count:
		phase = Phase.FINISHED
		push_error("Inventory exceeds the number of collection gaps.")
		return

	# Disable and hide Side A.
	spotlights.process_mode = Node.PROCESS_MODE_DISABLED
	spotlights.hide()
	pressure_display.hide()

	var side_b := SIDE_B_SCENE.instantiate() as Node2D
	side_b.connect("side_b_finished", _on_side_b_finished)

	add_child(side_b)
	phase = Phase.SIDE_B

	print("Side A gap count: ", gap_count)
	print("Side B encounters: ", encounters)

	side_b.call("start", player, inventory, encounters)


func _on_side_b_finished(success: bool) -> void:
	phase = Phase.FINISHED

	if success:
		print("Round completed")
	else:
		print("Round failed")
