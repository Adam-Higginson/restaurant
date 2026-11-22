class_name FishingLine
extends RefCounted
## A fishing line's patience, with no picture attached: cast it, wait, a fish
## bites, and you have a moment to strike before it gets away. [FishingSpot]
## draws it at the rail.
##
## Fish only bite while the ship is still (hove to): the wake scares them off.
## Waiting is paused while the ship is under way.

## Emitted when a fish takes the bait: strike now!
signal bitten
## Emitted when a biting fish gets away because you didn't strike in time.
signal got_away

enum State { REELED_IN, WAITING, BITING }

## The shortest and longest wait for a bite, in seconds of the ship being still.
var min_wait: float = 4.0
var max_wait: float = 10.0
## How long a fish stays on the hook before it gets away, in seconds.
var bite_window: float = 1.6

## Whether the line is out, and whether something's biting.
var state: State:
	get:
		return _state

var _state: State = State.REELED_IN
var _left: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _init(seed_value: int = 0) -> void:
	if seed_value != 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()


## Casts the line out. Does nothing if it's already out.
func cast() -> void:
	if _state != State.REELED_IN:
		return
	_state = State.WAITING
	_left = _rng.randf_range(min_wait, max_wait)


## Reels the line in. Returns whether a fish came with it (it was biting).
func reel() -> bool:
	var caught: bool = _state == State.BITING
	_state = State.REELED_IN
	return caught


## Moves time on by [param delta] seconds. Fish only come while
## [param still_water] is true; a bite already on the hook keeps going.
func step(delta: float, still_water: bool) -> void:
	match _state:
		State.WAITING:
			if not still_water:
				return
			_left -= delta
			if _left <= 0.0:
				_state = State.BITING
				_left = bite_window
				bitten.emit()
		State.BITING:
			_left -= delta
			if _left <= 0.0:
				_state = State.WAITING
				_left = _rng.randf_range(min_wait, max_wait)
				got_away.emit()
