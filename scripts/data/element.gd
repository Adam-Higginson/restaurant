class_name Element
extends Resource
## Something a vessel's surroundings provide, rather than a physical item: the
## knife's cut, a burner's fire, a fridge's cold. One .tres file per element
## under res://data/elements/.

## How an element reaches a vessel and drives reactions.
enum Kind {
	## Arrives in one-off steps and doesn't stay, like each press of the knife.
	INSTANT,
	## Stays until removed and counts seconds while present, like a lit burner.
	TIMED,
}

## Stable internal name (e.g. &"cut"). Saves will refer to this, so don't change it.
@export var id: StringName = &""
@export var display_name: String = ""
@export var kind: Kind = Kind.INSTANT
