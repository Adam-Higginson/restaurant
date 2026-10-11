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
	if has_run_out():
		return
	_left = maxf(_left - delta, 0.0)
	if has_run_out():
		ran_out.emit()


## How much patience is left, from 1 (full) to 0 (none).
func fraction() -> float:
	if _total == 0.0:
		return 0.0

	return _left / _total


func seconds_left() -> float:
	return _left


func has_run_out() -> bool:
	return _left <= 0.0
