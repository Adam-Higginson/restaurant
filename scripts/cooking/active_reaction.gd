class_name ActiveReaction
extends RefCounted
## A [Reaction] happening right now in a vessel, with the items it's using and
## how far along it is. Created and advanced by [VesselContents]; other code
## only reads it.

var reaction: Reaction
## Items this reaction will use up. No other reaction can use them meanwhile.
var consumed: Array[ItemInstance] = []
## Items that must stay present, which other reactions may share.
var required: Array[ItemInstance] = []
## Steps or seconds of the driving element so far.
var progress: float = 0.0
## How well each step so far was done, for an instant element (each cut on
## the chop meter, #152): 3 perfect, 2 good, 1 ragged. Empty when nothing
## graded the steps.
var step_grades: Array[int] = []


func _init(
	source: Reaction, consumed_items: Array[ItemInstance], required_items: Array[ItemInstance]
) -> void:
	reaction = source
	consumed = consumed_items
	required = required_items


## How far along it is, from 0 to 1, for progress bars.
func get_fraction() -> float:
	if reaction.is_immediate() or reaction.amount <= 0.0:
		return 1.0
	return clampf(progress / reaction.amount, 0.0, 1.0)


## Whether it's done and ready to turn into its result.
func is_complete() -> bool:
	return reaction.is_immediate() or progress >= reaction.amount


## How well it's been made, as a reaction's quality (1 to 3): the average
## of its [member step_grades], rounded up, but never better than the
## reaction's own [member Reaction.quality] (a shortcut stays a shortcut).
## Without graded steps, just the reaction's quality.
func method_quality() -> int:
	if step_grades.is_empty():
		return reaction.quality
	var total: int = 0
	for grade: int in step_grades:
		total += grade
	return mini(ceili(float(total) / step_grades.size()), reaction.quality)


## Whether it uses [param instance], consumed or required.
func uses(instance: ItemInstance) -> bool:
	return consumed.has(instance) or required.has(instance)
