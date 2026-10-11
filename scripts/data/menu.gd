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
	var result: Array[Item] = []
	result.assign(prices.keys())
	return result


func has_dish(dish: Item) -> bool:
	return prices.has(dish)


## What [param dish] costs, or 0 if it isn't on the menu.
func price_of(dish: Item) -> int:
	return prices.get(dish, 0)
