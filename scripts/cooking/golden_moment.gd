class_name GoldenMoment
extends RefCounted
## The golden moment of something cooked over heat (#152): when a
## [member Reaction.golden_moment] reaction finishes, its food is at its
## best for a moment. Take it off the heat inside the window (take the food
## out, lift the pan off the hob, or turn the heat off) and it's made
## perfectly; leave it and it's simply done, a star less. Nothing burns.
## Made and counted down by [VesselContents]; other code only reads it.

## The food that's cooking to its best.
var result: ItemInstance
## The reaction that made it.
var reaction: Reaction
## The qualities of what went into it, to work out its quality caught.
var input_qualities: Array[int] = []
## How long the window lasts in all, and how much of it is left, in seconds.
var seconds: float = 0.0
var seconds_left: float = 0.0


func _init(made: ItemInstance, from: Reaction, inputs: Array[int], window: float) -> void:
	result = made
	reaction = from
	input_qualities = inputs
	seconds = window
	seconds_left = window


## How much of the window is left, from 1 (just opened) to 0 (missed).
func fraction_left() -> float:
	return clampf(seconds_left / seconds, 0.0, 1.0) if seconds > 0.0 else 0.0
