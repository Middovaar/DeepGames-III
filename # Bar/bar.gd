extends Control

@export var MaxBarSize:float = 550.0


## Recieve Score from signal
func _RecieveScore(Score, Max):
	#If the values recieved are beyond defined bounds, stop everything
	if Score/Max < 0.0 or Score/Max > 1.0:
		push_error("Score is beyond the defined bounds")
		breakpoint
	
	#Clamp the calculated val between 0.0 and Max size of the bar.
	size.x = clampf(Score/Max * MaxBarSize, 0.0, MaxBarSize)
