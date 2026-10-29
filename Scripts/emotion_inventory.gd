extends Node

# Notify the UI when an emotion's quantity changes.
signal inventory_changed(emotion: String, quantity: int)

# Assign the Player node in the Inspector.
@export var player: Node2D

# Store the quantities collected during this run.
var counts: Dictionary = {
	"sad": 0,
	"shy": 0,
	"angry": 0,
}


func _ready() -> void:
	if player == null:
		push_error("Assign Player to EmotionInventory in the Inspector.")
		return

	player.connect("emoji_collected", add_emotion)


func add_emotion(emotion: String) -> void:
	if not counts.has(emotion):
		return

	counts[emotion] += 1
	inventory_changed.emit(emotion, counts[emotion])

	# Temporary output for checking inventory changes.
	print("Inventory: ", counts)
