class_name Recipe
extends Resource
## How to make a dish, as written in the galley's recipe book: a title and a
## few short steps. One .tres file per recipe under res://data/recipes/.

## Stable internal name.
@export var id: StringName = &""
## The dish it makes.
@export var dish: Item
## What the book calls it.
@export var title: String = ""
## The steps, in order, a line each.
@export_multiline var steps: PackedStringArray = PackedStringArray()
