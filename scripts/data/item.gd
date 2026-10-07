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
