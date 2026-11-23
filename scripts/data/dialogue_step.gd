class_name DialogueStep
extends Resource
## One statement of a dialogue script: somebody's line, a reply to pick, a
## change to a flag, a cue for the scene, or a jump. Made by
## [DialogueScript] from a line of a [code].dlg[/code] file.

## What a step does.
enum Kind {
	## Somebody says something: [member speaker], [member text], [member tag].
	LINE,
	## A reply the player can pick: [member text], then on to [member target].
	CHOICE,
	## Changes [member flag] by [member change] and [member amount].
	SET,
	## Tells the scene something: [member cue] and [member args].
	CUE,
	## Carries on from the section called [member target].
	JUMP,
}

## How a [constant Kind.SET] step changes its flag.
enum Change {
	## Sets it to the amount.
	TO,
	## Adds the amount (which may be negative).
	BY,
}

## The section name that ends the conversation.
const END: StringName = &"END"
## The speaker written for a line nobody says, shown with no name:
## [code]narrator: You got the *Cheap Chef's Knife*![/code]. Stored as &"".
const NARRATOR: StringName = &"narrator"

@export var kind: Kind = Kind.LINE
## The condition this step runs under, as written, or "" for always.
@export var guard: String = ""
## Whether this step runs only when the guard before it failed.
@export var is_else: bool = false
## Who says a line: a [member Person.id], or &"" for a narrator.
@export var speaker: StringName = &""
## The words of a line or a choice.
@export var text: String = ""
## A line's tag, the word in square brackets at its end, or &"".
@export var tag: StringName = &""
## The section a jump or a choice goes to, or [constant END].
@export var target: StringName = &""
## The flag a set step changes.
@export var flag: StringName = &""
@export var change: Change = Change.TO
@export var amount: int = 1
## A cue's name: the word after the @.
@export var cue: StringName = &""
## The words after a cue's name.
@export var args: PackedStringArray = PackedStringArray()
## The line of the script this came from, for error messages.
@export var line_number: int = 0
