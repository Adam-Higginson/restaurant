class_name SternSwing
extends Node3D
## Swings whatever hangs from it, like a lantern on a hook in a seaway: side
## to side about its own forward axis, easing in and out. Switch
## [member swinging] off and the swing dies away over a moment instead of
## stopping dead (he's gone still: he's heard something).

## Whether it's swinging. A clip switches this.
@export var swinging: bool = true
## How far it swings to each side, in radians.
@export var reach: float = 0.6
## How long one full swing there and back takes, in seconds.
@export var period: float = 3.6
## How quickly the swing dies away or builds up: higher is quicker.
@export var settle_speed: float = 4.0

## How much of its full swing it has now, 0 to 1.
var liveliness: float:
	get:
		return _liveliness

var _liveliness: float = 1.0
var _time: float = 0.0


func _ready() -> void:
	_liveliness = 1.0 if swinging else 0.0


func _process(delta: float) -> void:
	_time += delta
	_liveliness = move_toward(_liveliness, 1.0 if swinging else 0.0, settle_speed * delta)
	rotation.z = angle_at(_time)


## The angle it hangs at [param time] seconds in, in radians, for how
## lively it is now.
func angle_at(time: float) -> float:
	if period <= 0.0:
		return 0.0
	return reach * _liveliness * sin(TAU * time / period)
