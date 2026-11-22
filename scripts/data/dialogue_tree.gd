class_name DialogueTree
extends Resource
## A whole conversation, parsed from a [code].dlg[/code] script by
## [DialogueScript]: its steps in order, and where each named section starts.
## A [DialogueRunner] walks it.

## The section a conversation starts at.
const START: StringName = &"start"

## The file's name without its ending, e.g. &"heron". Flags and saves refer
## to it, so don't rename a script lightly.
@export var id: StringName = &""
## Every step, in the order written. Each section ends with a jump to END.
@export var steps: Array[DialogueStep] = []
## Where each section starts in [member steps], by name.
@export var sections: Dictionary[StringName, int] = {}
## What's wrong with the script, each with its line number. Empty when it's fine.
@export var errors: PackedStringArray = PackedStringArray()


## Whether there's a section called [param section].
func has_section(section: StringName) -> bool:
	return sections.has(section)


## Everyone who speaks in this tree, by [member Person.id].
func speakers() -> Array[StringName]:
	var found: Array[StringName] = []
	for step: DialogueStep in steps:
		if step.kind == DialogueStep.Kind.LINE and step.speaker != &"" \
				and not found.has(step.speaker):
			found.append(step.speaker)
	return found
