class_name EmotionMonster
extends Node2D

signal response_entered(monster: EmotionMonster)
signal encounter_resolved(monster: EmotionMonster, success: bool)

const FACE_TEXTURES: Dictionary = {
	"sad": preload("res://Assets/Art Assets/Icon/FaceWithoutBG2.png"),
	"shy": preload("res://Assets/Art Assets/Icon/FaceWithoutBG3.png"),
	"angry": preload("res://Assets/Art Assets/Icon/FaceWithoutBG4.png"),
}

@export_enum("sad", "shy", "angry")
var required_emotion: String = "sad"

@export var speed: float = 120.0

var active: bool = false
var in_response_range: bool = false
var resolved: bool = false

@onready var face: Sprite2D = $Face
@onready var response_area: Area2D = $ResponseArea


func _ready() -> void:
	face.texture = FACE_TEXTURES[required_emotion]

	response_area.area_entered.connect(_on_area_entered)
	response_area.area_exited.connect(_on_area_exited)


func start() -> void:
	if resolved:
		return

	active = true


func _physics_process(delta: float) -> void:
	if not active:
		return

	position.x -= speed * delta

	# Remove the monster after it leaves the screen.
	if global_position.x < -200.0:
		if not resolved:
			resolve(false)

		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if not active or resolved:
		return

	# Physics layer 2 is reserved for the player.
	if not area.get_collision_layer_value(2):
		return

	in_response_range = true
	response_entered.emit(self)

	print("Monster in response range: ", required_emotion)


func _on_area_exited(area: Area2D) -> void:
	if not area.get_collision_layer_value(2):
		return

	in_response_range = false

	# Leaving without a response counts as one failed encounter.
	if active and not resolved:
		resolve(false)

func resolve(success: bool) -> void:
	# Resolve each monster only once.
	if resolved:
		return

	resolved = true
	in_response_range = false

	# Failed monsters keep moving until they leave the screen.
	active = not success

	encounter_resolved.emit(self, success)

	if success:
		queue_free()

func _draw() -> void:
	var collision := get_node(
		"ResponseArea/CollisionShape2D"
	) as CollisionShape2D

	var circle := collision.shape as CircleShape2D
	if circle == null:
		return

	# Draw a translucent response area behind the monster.
	draw_circle(
		Vector2.ZERO,
		circle.radius,
		Color(1.0, 1.0, 1.0, 0.10)
	)

	# Draw the visible boundary of the response area.
	draw_arc(
		Vector2.ZERO,
		circle.radius,
		0.0,
		TAU,
		96,
		Color(1.0, 1.0, 1.0, 0.65),
		2.0,
		true
	)
