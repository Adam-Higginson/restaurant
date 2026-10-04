class_name Catalog
extends Resource
## Every ingredient and dish in the game, so other code doesn't need to know
## file paths. The game's catalog is res://data/catalog.tres.

const PATH: String = "res://data/catalog.tres"

@export var ingredients: Array[Ingredient] = []
## The dishes on the menu, which customers order from.
@export var dishes: Array[Dish] = []


## Loads the game's catalog.
static func load_default() -> Catalog:
	return load(PATH) as Catalog
