extends MarginContainer

# Assign the inventory node in the Inspector.
@export var inventory: Node

# Map emotion IDs to their quantity labels.
@onready var count_labels: Dictionary = {
	"sad": $Rows/SadRow/Count,
	"shy": $Rows/ShyRow/Count,
	"angry": $Rows/AngryRow/Count,
}


func _ready() -> void:
	if inventory == null:
		push_error("Assign EmotionInventory to EmotionPanel in the Inspector.")
		return

	inventory.connect("inventory_changed", _on_inventory_changed)

	# Display the current quantities when the UI starts.
	var quantities: Dictionary = inventory.get("counts")

	for emotion: String in quantities:
		_on_inventory_changed(emotion, quantities[emotion])


func _on_inventory_changed(emotion: String, quantity: int) -> void:
	if not count_labels.has(emotion):
		return

	var count_label: Label = count_labels[emotion]
	count_label.text = "× %d" % quantity
