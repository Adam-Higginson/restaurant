class_name ChopMeter
extends RefCounted
## The chop meter at the chopping board (#152), like Stardew Valley's fishing
## bar: a marker sweeps back and forth along a bar, and a cut is graded by
## where it is when you cut. In the middle of the bar is the sweet spot: a
## cut there is perfect; a little either side, good; anywhere else, ragged.
## A better knife has a wider sweet spot ([member HandTool.sweet_spot]).
##
## Pure logic with no nodes: a [Counter3D] with a board ticks it while the
## meter's up, asks for a [method grade] on each cut, and the HUD draws it.

## How well a cut was made. The numbers are its quality, in stars.
enum Grade {
	RAGGED = 1,
	GOOD = 2,
	PERFECT = 3,
}

## Where the marker is along the bar, 0 (left) to 1 (right).
var position: float = 0.0
## Where the middle of the sweet spot is, 0 to 1.
var centre: float = 0.5
## How much of the bar is perfect, and how much (including the perfect
## part) is at least good, as shares of it.
var perfect_width: float = 0.12
var good_width: float = 0.34
## How long the marker takes to cross the bar once, in seconds.
var sweep_seconds: float = 0.9

var _direction: float = 1.0


func _init(perfect: float = 0.12, good: float = 0.34, seconds: float = 0.9) -> void:
	set_zones(perfect, good)
	sweep_seconds = maxf(seconds, 0.05)


## Sets the sweet spot's widths: [param perfect] and [param good] as shares
## of the bar (good includes perfect, and is never narrower).
func set_zones(perfect: float, good: float) -> void:
	perfect_width = clampf(perfect, 0.0, 1.0)
	good_width = clampf(maxf(good, perfect_width), 0.0, 1.0)


## Sets the zones from [param tool]'s sweet spot.
func fit_to(tool: HandTool) -> void:
	if tool != null:
		set_zones(tool.sweet_spot, tool.good_spot)


## Moves the marker on by [param seconds], bouncing off each end.
func tick(seconds: float) -> void:
	position += _direction * seconds / sweep_seconds
	# A long tick could carry it past both ends, so bounce until it's on the bar.
	while position > 1.0 or position < 0.0:
		if position > 1.0:
			position = 2.0 - position
			_direction = -1.0
		else:
			position = -position
			_direction = 1.0


## How a cut made now would come out.
func grade() -> Grade:
	var off: float = absf(position - centre)
	if off <= perfect_width / 2.0:
		return Grade.PERFECT
	if off <= good_width / 2.0:
		return Grade.GOOD
	return Grade.RAGGED


## Puts the marker back at the left end, moving right: a fresh start for
## the next thing on the board.
func reset() -> void:
	position = 0.0
	_direction = 1.0


## Which way the marker is moving: 1 right, -1 left.
func direction() -> float:
	return _direction
