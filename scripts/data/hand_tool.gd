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
## What using it is called in the HUD prompt (the knife chops).
@export var verb: String = "Use"
## What using the tool applies to the thing it's used on (the knife cuts).
@export var element: Element = null
## How forgiving the tool is on the chop meter ([ChopMeter]): how much of
## the bar is its sweet spot for a perfect cut, and how much is at least a
## good cut, as shares of the bar. A better knife has wider ones.
@export_range(0.0, 1.0) var sweet_spot: float = 0.12
@export_range(0.0, 1.0) var good_spot: float = 0.34
## How hard it cuts in a fight: each cut's damage is multiplied by this.
## 1 for the cheap knife; a better one hits harder.
@export var damage: float = 1.0
## The tool's model, shown when it's held up out of a chest: a file under
## res://assets/third_party/, fitted into [member model_size] standing up.
## Without one (or on a fresh clone) a greybox bar in [member color] shows.
@export_file("*.gltf", "*.glb") var model_path: String = ""
@export var model_size: Vector3 = Vector3(0.15, 0.6, 0.06)
## Whether this is the recipe book (#184): not used on anything, but read.
## Selected and Used, it opens wherever you are, whatever's in reach.
@export var is_recipe_book: bool = false
## How far its model is turned about its forward axis when it's held up as
## a treasure, to stand it up, in degrees: our knife lies along X, point at
## -X, so -90 stands it point up (#207).
@export var hold_up_turn_degrees: float = -90.0

## The conversation flag that says the player owns this tool
## ([code]has_chefs_knife[/code]). Flags are saved with the voyage, so a tool
## found in a chest stays found; a script can also give one with
## [code]set has_chefs_knife[/code].
var owned_flag: StringName:
	get:
		return StringName("has_%s" % id)
