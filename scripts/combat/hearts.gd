class_name Hearts
extends RefCounted
## The player's health, counted in half-hearts so a hit can cost half a heart
## without fractions: three hearts are six halves. Plain data with no node, so
## the rules can be tested on their own. See Combat in docs/GDD.md.

## Emitted whenever the number of half-hearts changes.
signal changed(halves: int)
## Emitted once when the last half-heart goes.
signal emptied

const HALVES_PER_HEART: int = 2

## How many half-hearts a full bar holds.
var max_halves: int:
	get:
		return _max_halves

## How many half-hearts are left, from 0 to [member max_halves].
var halves: int:
	get:
		return _halves

var _max_halves: int = 0
var _halves: int = 0


func _init(hearts: int = 3) -> void:
	_max_halves = maxi(hearts, 1) * HALVES_PER_HEART
	_halves = _max_halves


## Takes [param amount] half-hearts away, stopping at none. Emits
## [signal emptied] if that was the last of them.
func hurt(amount: int = 1) -> void:
	if amount <= 0 or _halves == 0:
		return
	_halves = maxi(_halves - amount, 0)
	changed.emit(_halves)
	if _halves == 0:
		emptied.emit()


## Fills every heart again.
func refill() -> void:
	if _halves == _max_halves:
		return
	_halves = _max_halves
	changed.emit(_halves)


## Whether no hearts are left.
func is_empty() -> bool:
	return _halves == 0
