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
## a shortcut. It nudges the inputs' quality up or down a star (see
## [method result_quality] and the GDD's Quality section).
@export_range(1, 3) var quality: int = 3
## Whether what it makes has a golden moment when it's done (#152, see
## [GoldenMoment]): caught, it's made at this reaction's [member quality];
## missed, a star less ([constant VesselContents.MISSED_QUALITY]). For the
## proper way of frying or boiling a dish; never a shortcut.
@export var golden_moment: bool = false


## The element whose steps or seconds count towards progress, or null for an
## immediate reaction. With several elements, the first one listed drives it.
func driving_element() -> Element:
	if elements.is_empty():
		return null
	return elements[0]


## Whether the reaction finishes as soon as its items are present.
func is_immediate() -> bool:
	return driving_element() == null


## The quality of the result made from inputs of [param input_qualities]:
## their average, rounded to the nearest star, nudged by how well it was made
## (#152). Made at its best (3) adds a star; made well (2) keeps it; made
## badly or by a shortcut (1) takes one away. Never below 1 or above 3. How
## well it was made is this reaction's [member quality], unless [param made]
## (1 to 3) says otherwise: how cleanly it was cut on the chop meter, or
## whether its golden moment was caught.
func result_quality(input_qualities: Array[int], made: int = 0) -> int:
	var method: int = made if made >= 1 else quality
	var start: int = 2
	if not input_qualities.is_empty():
		var total: int = 0
		for value: int in input_qualities:
			total += value
		# Rounded to the nearest, a half up, kept exact: (2 * total + count) / (2 * count).
		start = floori(float(2 * total + input_qualities.size()) / (2 * input_qualities.size()))
	return clampi(start + method - 2, 1, 3)
