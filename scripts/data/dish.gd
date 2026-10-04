class_name Dish
extends Resource
## A dish customers can order. One .tres file per dish under res://data/dishes/.

## Which kind of station cooks a dish.
enum StationType { CHOPPING_BOARD, STOVE }

## Stable internal name (e.g. &"tomato_soup"). Saves will refer to this, so don't change it.
@export var id: StringName = &""
@export var display_name: String = ""
## What the customer pays, in coins.
@export var price: int = 0
@export var station: StationType = StationType.CHOPPING_BOARD
## Seconds the station takes to cook it.
@export var cook_time: float = 1.0
## The recipe: how many of each ingredient one dish uses.
@export var ingredients: Dictionary[Ingredient, int] = {}
## Placeholder colour until there's real art.
@export var color: Color = Color.WHITE
