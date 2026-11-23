class_name Item
extends Resource
## Anything physical in the world: an ingredient, prepared food, a dish or a
## utensil. One .tres file per item under res://data/items/.
##
## Every state food can be in is its own item (tomato, sliced tomato, diced
## tomato), so only designed states exist. [Reaction]s turn items into others.

## Where food is kept. NONE for things that can't be stored: utensils, plates
## and liquids. PANTRY is only a container's kind, never an item's: a pantry
## takes any food that can be stored. New kinds go at the end, because the
## .tres files save them as numbers.
enum StorageKind { NONE, FRIDGE, CUPBOARD, PANTRY }
## How a vessel is drawn: flat (a board or plate), a bowl, a pan with a long
## handle, or a deep pot. New shapes go at the end (saved as numbers).
enum VesselShape { FLAT, BOWL, PAN, POT }

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
## Which container it can be put away in. See Storage in docs/GDD.md.
@export var storage: StorageKind = StorageKind.NONE
## For vessels, how it's drawn (see [ItemModel]).
@export var vessel_shape: VesselShape = VesselShape.FLAT
## For cookware: how long food's golden moment lasts in it, in seconds
## (see [GoldenMoment]). A better pan gives you longer to catch it.
@export var golden_window: float = 1.5


## Whether food can go in it. Vessels never go inside other vessels.
func is_vessel() -> bool:
	return capacity > 0
