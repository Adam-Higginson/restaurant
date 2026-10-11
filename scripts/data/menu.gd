class_name Menu
extends Resource
## The dishes the restaurant sells and what each costs. The game's menu is
## res://data/menu.tres.
##
## Prices live here, not on the items, so any dish can go on the menu.

const PATH: String = "res://data/menu.tres"

## Each dish on the menu and its price in coins.
@export var prices: Dictionary[Item, int] = {}


## Loads the game's menu.
static func load_default() -> Menu:
	return load(PATH) as Menu


## The dishes on the menu, in the order they were added.
func dishes() -> Array[Item]:
	# TODO 1: Return the dishes (the keys of `prices`) as an Array[Item].
	# `prices.keys()` gives a plain, untyped Array, which can't be returned as
	# an Array[Item] directly. Make a typed array and fill it with
	# `result.assign(prices.keys())`.
	return []


func has_dish(dish: Item) -> bool:
	# TODO 2: Whether `dish` is on the menu. Dictionary has a method for this.
	return false


## What [param dish] costs, or 0 if it isn't on the menu.
func price_of(dish: Item) -> int:
	# TODO 3: The dish's price, or 0 if it isn't on the menu.
	# `Dictionary.get(key, default)` does both in one call.
	return 0
