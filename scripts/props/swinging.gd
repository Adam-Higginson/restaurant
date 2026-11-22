class_name Swinging
extends Node3D
## Something hanging that swings gently, like a lantern on a hook: it rocks
## about its own origin (put the origin where it hangs from), side to side
## and a little fore and aft, as if the sea were rolling the ship.
##
## The ship itself stays still, so this is where the sea's motion shows
## aboard. Swings are small and slow so nothing on screen lurches.

## The widest swing to each side, in degrees.
@export var swing_degrees: float = 4.0
## Seconds for one full swing, out and back.
@export var period: float = 3.6
## Where in its swing this one starts, 0 to 1, so neighbours don't swing in
## step.
@export_range(0.0, 1.0) var phase: float = 0.0

var _time: float = 0.0
var _rest: Basis = Basis.IDENTITY


func _ready() -> void:
	# How it hangs at rest (turned to face along a wall, say). The swing is
	# added to this rather than replacing it, so it keeps facing the same way.
	_rest = basis
	_swing_to(0.0)


# On physics ticks, so it moves smoothly with physics interpolation like the
# rest of the ship.
func _physics_process(delta: float) -> void:
	_time += delta
	_swing_to(_time)


func _swing_to(time: float) -> void:
	basis = _rest * Basis.from_euler(angle_at(time))


## The swing's rotation at [param time] seconds, in radians: a side-to-side
## sway (z) and a smaller, slower fore-and-aft sway (x), so the path traces a
## lazy oval rather than a stiff pendulum.
func angle_at(time: float) -> Vector3:
	if period <= 0.0:
		return Vector3.ZERO
	var turn: float = TAU * (time / period + phase)
	var widest: float = deg_to_rad(swing_degrees)
	return Vector3(widest * 0.35 * sin(turn * 0.71 + 1.3), 0.0, widest * sin(turn))
