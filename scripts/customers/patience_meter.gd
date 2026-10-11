class_name PatienceMeter
extends RefCounted
## How long a customer will keep waiting, with no nodes, so it's tested on its
## own. The customer drains it while they wait for their order.

## Emitted once, the moment patience reaches zero.
signal ran_out

var _total: float = 0.0
var _left: float = 0.0


func _init(seconds: float) -> void:
	_total = seconds
	_left = seconds


## Takes [param delta] seconds off. Never goes below zero, and emits
## [signal ran_out] once when it gets there.
func drain(delta: float) -> void:
	# TODO 3:
	#   a. If it has already run out, do nothing. That's what stops `ran_out`
	#      firing twice.
	#   b. Take `delta` off `_left`, but never below 0 (`maxf` helps).
	#   c. If that made it run out, emit `ran_out`.
	pass


## How much patience is left, from 1 (full) to 0 (none).
func fraction() -> float:
	# TODO 2: `_left` as a share of `_total`. Return 0.0 if `_total` is 0, so
	# a customer with no patience doesn't divide by zero.
	return 0.0


func seconds_left() -> float:
	# TODO 1: Return `_left`.
	return 0.0


func has_run_out() -> bool:
	# TODO 1: Whether there's no patience left.
	return false
