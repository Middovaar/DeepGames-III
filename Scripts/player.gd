extends Node2D
# Notify other systems when gap availability changes.
signal gap_changed(active: bool)

# Notify the inventory system when one emoji is collected.
signal emoji_collected(emotion: String)

# Map collectible expressions to their input actions.
const COLLECT_ACTIONS: Dictionary = {
	"sad": "emoji_sad",
	"shy": "emoji_shy",
	"angry": "emoji_angry",
}

# Required holding time, in seconds.
@export_range(0.1, 2.0, 0.1) var collect_duration: float = 0.6

var charge_time: float = 0.0
var collected_this_hold: bool = false

@onready var collect_bar: ProgressBar = $CollectBar
# Allow collection only when no spotlight overlaps the player.
var gap_active: bool = false

# Use Head to detect overlapping spotlight areas.
@onready var head: Area2D = $Head
# Notify other systems when the current expression changes.
signal expression_changed(emotion: String)

# Store the player's current expression.
var current_emotion: String = "default"
# Map each expression to its image.
const EMOTION_TEXTURES: Dictionary = {
	"default": preload("res://Assets/Art Assets/Icon/DefaultFace.png"),
	"smile": preload("res://Assets/Art Assets/Icon/Smile.png"),
	"sad": preload("res://Assets/Art Assets/Icon/Sad.png"),
	"shy": preload("res://Assets/Art Assets/Icon/Shy.png"),
	"angry": preload("res://Assets/Art Assets/Icon/Angry.png"),
}

@onready var emoji_sprite: Sprite2D = $EmojiSprite
# Find the Emoji label under Player.
@onready var emoji_label: Label = $Emoji


func _ready() -> void:
	set_expression(current_emotion)

func _unhandled_key_input(event: InputEvent) -> void:
	# Reset immediately when the selected collection key is released.
	var action: String = COLLECT_ACTIONS.get(current_emotion, "")

	if not action.is_empty() and event.is_action_released(action):
		_reset_charge()

	if event.is_action_pressed("emoji_smile"):
		set_expression("smile")

	elif event.is_action_pressed("emoji_sad"):
		set_expression("sad")

	elif event.is_action_pressed("emoji_shy"):
		set_expression("shy")

	elif event.is_action_pressed("emoji_angry"):
		set_expression("angry")
		
func set_expression(emotion: String) -> void:
	# Remember the expression before updating it.
	var previous_emotion: String = current_emotion

	current_emotion = emotion
	emoji_label.text = emotion.to_upper()
	emoji_sprite.texture = EMOTION_TEXTURES[emotion]

	# Emit the signal only when the expression changes.
	if current_emotion != previous_emotion:
		_reset_charge()
		expression_changed.emit(current_emotion)
		print("Expression changed to: ", current_emotion)
		
func _physics_process(_delta: float) -> void:
	var is_watched: bool = false

	# Physics layer 1 is reserved for spotlight areas.
	for area: Area2D in head.get_overlapping_areas():
		if area.get_collision_layer_value(1):
			is_watched = true
			break

	var new_gap_active: bool = not is_watched

	# Notify other systems only when the state changes.
	if new_gap_active == gap_active:
		return

	gap_active = new_gap_active
	gap_changed.emit(gap_active)

	# Temporary output for checking spotlight detection.
	if gap_active:
		print("Gap started")
	else:
		print("Under spotlight")
func _process(delta: float) -> void:
	collect_bar.visible = gap_active

	var action: String = COLLECT_ACTIONS.get(current_emotion, "")

	# Release the collection lock when the selected key is not held.
	if action.is_empty() or not Input.is_action_pressed(action):
		_reset_charge()
		return

	# Discard unfinished progress outside gaps.
	if not gap_active:
		charge_time = 0.0
		collect_bar.value = 0.0
		return

	# Collect at most one emoji per continuous hold.
	if collected_this_hold:
		return

	charge_time = minf(charge_time + delta, collect_duration)
	collect_bar.value = charge_time / collect_duration * 100.0

	if charge_time >= collect_duration:
		collected_this_hold = true
		emoji_collected.emit(current_emotion)
		print("Collected emoji: ", current_emotion)


func _reset_charge() -> void:
	charge_time = 0.0
	collected_this_hold = false
	collect_bar.value = 0.0
