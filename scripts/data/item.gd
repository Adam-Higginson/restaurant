class_name Item
extends Resource
## Anything physical in the world: an ingredient, prepared food, a dish or a
## utensil. One .tres file per item under res://data/items/.
##
## Every state food can be in is its own item (tomato, sliced tomato, diced
## tomato), so only designed states exist. [Reaction]s turn items into others.

## Stable internal name (e.g. &"sliced_tomato"). Saves will refer to this, so don't change it.
@export var id: StringName = &""
@export var display_name: String = ""
## Placeholder colour until there's real art.
@export var color: Color = Color.WHITE
## How many food items fit in it, for vessels (a chopping board, a plate).
## 0 for everything else, including food.
@export var capacity: int = 0
## Whether pick up takes it whole with its food (a plate or bowl). Otherwise
## pick up takes its top food item, and the vessel itself only once it's empty
## (a chopping board or pan).
@export var carried_whole: bool = false


## Whether food can go in it. Vessels never go inside other vessels.
func is_vessel() -> bool:
	return capacity > 0
