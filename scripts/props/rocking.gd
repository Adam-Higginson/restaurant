class_name Rocking
extends Node3D
## Something sitting loose that rocks gently with the sea: a tankard, a bowl,
## a loaf on the table. It tips a little back and forth about its own origin,
## on top of however it was placed, and never slides, so nothing falls off.
##
## Not physics, just a slow sway like [Swinging]'s, smaller and quicker.

## The widest tip either way, in degrees.
@export var tip_degrees: float = 1.5
## Seconds for one full rock, back and forth.
@export var period: float = 2.6
## Where in its rock this one starts, 0 to 1, so neighbours don't rock in step.
@export_range(0.0, 1.0) var phase: float = 0.0

var _rest: Basis = Basis.IDENTITY
var _time: float = 0.0


func _ready() -> void:
	_rest = basis
	basis = _rest * Basis.from_euler(tip_at(0.0))


# On physics ticks, so it moves smoothly with physics interpolation like the
# ship around it.
func _physics_process(delta: float) -> void:
	_time += delta
	basis = _rest * Basis.from_euler(tip_at(_time))


## The tip at [param time] seconds, in radians: mostly side to side (z), a
## little fore and aft (x), never turning (y).
func tip_at(time: float) -> Vector3:
	if period <= 0.0:
		return Vector3.ZERO
	var turn: float = TAU * (time / period + phase)
	var widest: float = deg_to_rad(tip_degrees)
	return Vector3(widest * 0.4 * sin(turn * 0.63 + 0.9), 0.0, widest * sin(turn))
