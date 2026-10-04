class_name Ingredient
extends Resource
## An ingredient the player can buy and cook with. One .tres file per ingredient
## under res://data/ingredients/.

## Stable internal name (e.g. &"tomato"). Saves will refer to this, so don't change it.
@export var id: StringName = &""
@export var display_name: String = ""
## Shop price in coins.
@export var price: int = 0
## Placeholder colour until there's real art.
@export var color: Color = Color.WHITE
