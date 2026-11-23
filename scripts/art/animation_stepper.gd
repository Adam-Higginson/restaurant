class_name AnimationStepper
extends RefCounted
## Makes an animation move in steps, a few poses a second, the way N64
## creatures were hand-keyed, while the game around it stays smooth.
##
## Each frame, hand [method take] the frame's time; it gives back how far to
## advance the animation: nothing until a whole step's time has gathered,
## then all of it at once. With no steps (0) it gives the time straight back.

## Poses a second; 0 for smooth.
var steps: float = 0.0

var _gathered: float = 0.0


func _init(poses_a_second: float = 0.0) -> void:
	steps = poses_a_second


## How far to advance the animation this frame, given [param delta]
## seconds have passed.
func take(delta: float) -> float:
	if steps <= 0.0:
		return delta
	_gathered += delta
	var step: float = 1.0 / steps
	if _gathered + 0.00001 < step:
		return 0.0
	var released: float = _gathered
	_gathered = 0.0
	return released
