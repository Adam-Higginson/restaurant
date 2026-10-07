class_name HandTool
extends Resource
## A tool that lives on the player's belt, like the knife. One .tres file per
## tool under res://data/tools/.
##
## Tools never go in the player's arms, and utensils never go on the belt. See
## the Player section of docs/GDD.md.

## Stable internal name (e.g. &"chefs_knife"). Saves will refer to this, so don't change it.
@export var id: StringName = &""
@export var display_name: String = ""
## Placeholder colour until there's real art.
@export var color: Color = Color.WHITE
## What using the tool applies to the thing it's used on (the knife cuts).
@export var element: Element = null
