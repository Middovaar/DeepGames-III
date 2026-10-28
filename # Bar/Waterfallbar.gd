@tool
extends ColorRect

@export var DepletionThresholdMax:float = 350.0
@export var DepletionThresholdMin:float = 80.0

# Cache the last size and threshold values to avoid redundant shader updates
var _last_size: Vector2 = Vector2.ZERO
var _last_max: float = -INF
var _last_min: float = -INF

func _ready() -> void:
	update_shader_resolution()

func _process(_delta: float) -> void:
	# In the editor, dragging handles to resize can bypass signals; 
	# running this in the editor tool mode ensures real-time updates.
	if Engine.is_editor_hint():
		update_shader_resolution()
	else:
		update_shader_resolution()

func update_shader_resolution() -> void:
	# Ensure the node has a ShaderMaterial assigned
	if not material is ShaderMaterial:
		return
	
	var current_size := size
	
	# Update shader parameters only when size or depletion thresholds change
	if current_size != Vector2.ZERO and (current_size != _last_size or DepletionThresholdMax != _last_max or DepletionThresholdMin != _last_min):
		_last_size = current_size
		_last_max = DepletionThresholdMax
		_last_min = DepletionThresholdMin
		
		var mat := material as ShaderMaterial
		mat.set_shader_parameter("sprite_or_color_rect_resolution", current_size)
		
		# Calculate dynamic gradient blending using the ease(-3.0) envelope
		var blend := 1.0
		if current_size.y >= DepletionThresholdMax:
			blend = 1.0
		elif current_size.y <= DepletionThresholdMin:
			blend = 0.0
		else:
			var t = inverse_lerp(DepletionThresholdMin, DepletionThresholdMax, current_size.y)
			blend = ease(t, -3.0)
			
		mat.set_shader_parameter("water_blend", blend)
