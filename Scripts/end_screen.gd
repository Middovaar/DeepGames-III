extends CanvasLayer
const RESULT_IMAGES: Dictionary = {
	"lose_a": preload("res://Assets/Art Assets/UI/LoseSceneA.png"),
	"lose_b": preload("res://Assets/Art Assets/UI/LoseSceneB_Transparent.png"),
	"win": preload("res://Assets/Art Assets/UI/WinScene.png"),
}

const RESULT_BACKGROUNDS: Dictionary = {
	"lose_a": preload("res://Assets/Art Assets/BackGround/SideABG_BGColor.png"),
	"lose_b": preload("res://Assets/Art Assets/BackGround/SideBBG_Grey.png"),
}
@onready var panel: Control = $Panel
@onready var artwork: TextureRect = $Panel/Artwork
@onready var restart_button: Button = $Panel/RestartButton
@onready var background_image: TextureRect = $Panel/BackgroundImage
@onready var curtain: TextureRect = $Panel/Curtain

func _ready() -> void:
	panel.hide()
	restart_button.pressed.connect(_on_restart_pressed)


func show_result(result: String) -> void:
	if not RESULT_IMAGES.has(result):
		push_error("Unknown result: " + result)
		return

		# Select the background for the current result.
	background_image.texture = RESULT_BACKGROUNDS.get(result)
	background_image.visible = background_image.texture != null

	# Show the stage curtain only after a Side A failure.
	curtain.visible = result == "lose_a"

	artwork.texture = RESULT_IMAGES[result]
	panel.show()

	# Stop gameplay while keeping this interface responsive.
	get_tree().paused = true
	restart_button.grab_focus()


func _on_restart_pressed() -> void:
	# Resume processing before loading a fresh game.
	get_tree().paused = false
	get_tree().reload_current_scene()
