class_name Catalog
extends Resource
## Every item, element and reaction in the game, so other code doesn't need to
## know file paths. The game's catalog is res://data/catalog.tres.

const PATH: String = "res://data/catalog.tres"

@export var items: Array[Item] = []
@export var elements: Array[Element] = []
## Tried in this order when two reactions with the same number of inputs compete.
@export var reactions: Array[Reaction] = []


## Loads the game's catalog.
static func load_default() -> Catalog:
	return load(PATH) as Catalog


## The item with [param id], or null if there isn't one.
func find_item(id: StringName) -> Item:
	for item: Item in items:
		if item.id == id:
			return item
	return null


## The element with [param id], or null if there isn't one.
func find_element(id: StringName) -> Element:
	for element: Element in elements:
		if element.id == id:
			return element
	return null
