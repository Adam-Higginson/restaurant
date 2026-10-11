class_name Person
extends Resource
## A townsperson: someone from town who eats at the restaurant. One .tres file
## per person under res://data/people/.
##
## Their tastes decide what they order from the [Menu]: loved dishes most,
## then liked ones, then anything else, and never a dish they dislike.

## How much more likely a loved dish is to be ordered than an ordinary one.
const LOVED_WEIGHT: int = 3
const LIKED_WEIGHT: int = 2
const OTHER_WEIGHT: int = 1

## Stable internal name (e.g. &"wren"). Saves will refer to this, so don't change it.
@export var id: StringName = &""
@export var display_name: String = ""
## Who they are in town ("blacksmith"). Not shown yet; a note for writing them.
@export var role: String = ""
## Placeholder colour until there's real art.
@export var color: Color = Color.WHITE
@export var loved: Array[Item] = []
@export var liked: Array[Item] = []
@export var disliked: Array[Item] = []
## Real seconds they'll wait for their order before leaving.
@export var patience_seconds: float = 120.0


## How likely they are to order [param dish]: [constant LOVED_WEIGHT],
## [constant LIKED_WEIGHT] or [constant OTHER_WEIGHT], or 0 if they dislike it.
## A dislike wins over everything else.
func taste_weight(dish: Item) -> int:
	# TODO 1: Check the lists in this order and return the matching weight:
	#   disliked -> 0, loved -> LOVED_WEIGHT, liked -> LIKED_WEIGHT,
	#   anything else -> OTHER_WEIGHT.
	# Checking `disliked` first is what makes a dislike win.
	return 0


## Whether [param menu] has at least one dish they'd order.
func can_order_from(menu: Menu) -> bool:
	# TODO 2: Loop over `menu.dishes()` and return true as soon as a dish has a
	# taste weight above 0. If none does (or the menu is empty), return false.
	return false


## Picks a dish from [param menu], weighted by [method taste_weight], using
## [param rng] so tests can control the roll. Returns null if there's nothing
## they'd order.
func choose_order(menu: Menu, rng: RandomNumberGenerator) -> Item:
	# TODO 3:
	#   a. If they can't order from the menu, return null.
	#   b. Build a PackedFloat32Array of weights, one per dish in
	#      `menu.dishes()`, in the same order.
	#   c. `rng.rand_weighted(weights)` returns a random index, where each
	#      index's chance is its weight divided by the total. A weight of 0 is
	#      never picked. Return the dish at that index.
	return null
