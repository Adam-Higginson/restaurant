class_name SeaCurrent
extends Node
## A current running through the sea, strong enough to take a small boat
## where it wants. [member takeover] says how much of a boat's steering
## belongs to the sea: at 0 the water is still and the rower is in charge,
## at 1 the current carries the boat along and the oars do nothing.
##
## The opening's sweep (#229) raises it slowly, so you lose control of the
## rowboat a little at a time instead of all at once.

## Emitted when [member takeover] reaches 1: the sea has the boat.
signal took_over

## Which way the water runs, in degrees: 0 runs towards -Z, 90 towards -X
## (the same way round as [WaveLayer]).
@export_range(0.0, 360.0) var direction_degrees: float = 0.0
## How fast the water runs at full takeover, in metres per second.
@export var speed: float = 4.0
## How much of the steering belongs to the sea, 0 to 1.
@export_range(0.0, 1.0) var takeover: float = 0.0:
	set(value):
		var was: float = takeover
		takeover = clampf(value, 0.0, 1.0)
		if was < 1.0 and takeover >= 1.0:
			took_over.emit()

var _sweep: Tween = null


## The flat direction the water runs, as x and z.
func direction() -> Vector2:
	var angle: float = deg_to_rad(direction_degrees)
	return Vector2(-sin(angle), -cos(angle))


## How the water is moving right now, as x and z in metres per second: its
## full speed scaled by [member takeover].
func flow() -> Vector2:
	return direction() * speed * takeover


## Raises (or lowers) [member takeover] to [param to] over [param seconds],
## easing in so the start is hard to notice. Await the returned tween's
## [code]finished[/code] to wait for it.
func sweep(to: float, seconds: float) -> Tween:
	if _sweep != null and _sweep.is_valid():
		_sweep.kill()
	_sweep = create_tween()
	_sweep.tween_property(self, "takeover", clampf(to, 0.0, 1.0), seconds) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	return _sweep


## Stops any sweep and gives the boat back: [member takeover] goes to 0.
func release() -> void:
	if _sweep != null and _sweep.is_valid():
		_sweep.kill()
	takeover = 0.0
