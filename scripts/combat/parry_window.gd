class_name ParryWindow
extends RefCounted
## The timing of a frying-pan parry. Pressing parry raises the pan for a
## short window; a hit that lands inside it is turned away. After the window
## the pan is down for a moment before it can be raised again, so holding or
## mashing the button doesn't parry everything.
##
## Plain data with no node: [method tick] moves time on.

## How long the pan is up after a press, in seconds.
var window_seconds: float = 0.3
## How long after the window before another press counts, in seconds.
var recovery_seconds: float = 0.4
## How soon after the pan goes up a hit must land to be parried perfectly,
## in seconds: raised just in time.
var perfect_seconds: float = 0.12

## Seconds of window left.
var _window_left: float = 0.0
## Seconds until another press counts (covers the window and the recovery).
var _busy_left: float = 0.0


## Raises the pan. Returns false, changing nothing, if it was raised too
## recently.
func press() -> bool:
	if _busy_left > 0.0:
		return false
	_window_left = window_seconds
	_busy_left = window_seconds + recovery_seconds
	return true


## Moves time on by [param delta] seconds.
func tick(delta: float) -> void:
	_window_left = maxf(_window_left - delta, 0.0)
	_busy_left = maxf(_busy_left - delta, 0.0)


## Whether a hit landing right now would be parried.
func is_active() -> bool:
	return _window_left > 0.0


## Whether a hit landing right now would be parried perfectly: the pan went
## up no more than [member perfect_seconds] ago.
func is_perfect() -> bool:
	return is_active() and window_seconds - _window_left <= perfect_seconds


## Ends the window at once (the parry has been used on a hit). The pan is
## ready again straight away, as a reward.
func spend() -> void:
	_window_left = 0.0
	_busy_left = 0.0
