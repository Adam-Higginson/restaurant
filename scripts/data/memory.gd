class_name Memory
extends Resource
## A taste of home: something you remember the first time you make, or catch,
## a particular thing. You remember home only as tastes and sounds (see the
## Story in docs/GDD.md), so these are small, sensory and a little out of
## focus. One .tres file per memory under res://data/memories/.

## Stable internal name. Saves will refer to this, so don't change it.
@export var id: StringName = &""
## The item that brings it back, the first time you make or catch one.
@export var trigger: Item
## A few words, like the title of a song.
@export var title: String = ""
## What comes back, a line at a time.
@export_multiline var lines: PackedStringArray = PackedStringArray()
