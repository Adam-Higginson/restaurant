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
	if disliked.has(dish):
		return 0
	if loved.has(dish):
		return LOVED_WEIGHT
	if liked.has(dish):
		return LIKED_WEIGHT

	return OTHER_WEIGHT


## Whether [param menu] has at least one dish they'd order.
func can_order_from(menu: Menu) -> bool:
	for dish: Item in menu.dishes():
		if taste_weight(dish) > 0:
			return true

	return false


## Picks a dish from [param menu], weighted by [method taste_weight], using
## [param rng] so tests can control the roll. Returns null if there's nothing
## they'd order.
func choose_order(menu: Menu, rng: RandomNumberGenerator) -> Item:
	if not can_order_from(menu):
		return null

	var dishes: Array[Item] = menu.dishes()
	var weights: PackedFloat32Array = PackedFloat32Array()
	for dish: Item in dishes:
		weights.append(taste_weight(dish))

	var selected_dish: int = rng.rand_weighted(weights)
	return dishes[selected_dish]
