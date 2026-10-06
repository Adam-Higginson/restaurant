class_name Reaction
extends Resource
## A cooking rule: when everything it needs is present in a vessel, it turns the
## items it consumes into [member result]. One .tres file per reaction under
## res://data/reactions/.
##
## For example, slicing a tomato consumes a tomato, requires a chopping board,
## and is driven by 2 steps of the cut element.

## Stable internal name (e.g. &"slice_tomato").
@export var id: StringName = &""
## Items used up by the reaction.
@export var consumes: Array[Item] = []
## Items that must be present but aren't used up, including the vessel itself
## (the chopping board, a pan of boiling water).
@export var requires: Array[Item] = []
## Elements that must be present. The first one drives progress (see
## [method driving_element]); any others just need to be there.
@export var elements: Array[Element] = []
## How much of the driving element it takes: steps for an instant element,
## seconds for a timed one. Ignored for immediate reactions.
@export var amount: float = 0.0
@export var result: Item
## Quality of this way of making [member result]: 3 for the proper method, 1 for
## a shortcut. Averaged with the inputs' quality (see the GDD's Quality section).
@export_range(1, 3) var quality: int = 3


## The element whose steps or seconds count towards progress, or null for an
## immediate reaction. With several elements, the first one listed drives it.
func driving_element() -> Element:
	if elements.is_empty():
		return null
	return elements[0]


## Whether the reaction finishes as soon as its items are present.
func is_immediate() -> bool:
	return driving_element() == null


## The quality of the result made from inputs of [param input_qualities]: the
## average of the inputs' average and this reaction's [member quality], rounded
## up so a near miss lands on the better star.
func result_quality(input_qualities: Array[int]) -> int:
	if input_qualities.is_empty():
		return quality
	var count: int = input_qualities.size()
	var total: int = 0
	for value: int in input_qualities:
		total += value
	# (total / count + quality) / 2, as one division so a whole-number answer
	# stays exact and isn't nudged up by float error.
	return ceili(float(total + quality * count) / (2 * count))
