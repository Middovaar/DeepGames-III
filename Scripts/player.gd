extends Node2D

# Notify other systems when the current expression changes.
signal expression_changed(emotion: String)

# Store the player's current expression.
var current_emotion: String = "smile"

# Find the Emoji label under Player.
@onready var emoji_label: Label = $Emoji


func _ready() -> void:
	set_expression(current_emotion)


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("emoji_smile"):
		set_expression("smile")

	elif event.is_action_pressed("emoji_angry"):
		set_expression("angry")

	elif event.is_action_pressed("emoji_left"):
		set_expression("left_tbd")

	elif event.is_action_pressed("emoji_right"):
		set_expression("right_tbd")


func set_expression(emotion: String) -> void:
	# Remember the expression before updating it.
	var previous_emotion: String = current_emotion

	current_emotion = emotion
	emoji_label.text = emotion.to_upper()

	# Emit the signal only when the expression changes.
	if current_emotion != previous_emotion:
		expression_changed.emit(current_emotion)

		# Temporary output for checking expression changes.
		print("Expression changed to: ", current_emotion)
