class_name ToolBelt
extends RefCounted
## The player's tool belt: a row of slots for hand tools, always with them,
## with one slot selected at a time. See the Player section of docs/GDD.md.
##
## Any slot can be selected, empty or not. Using the selected tool needs empty
## arms; that rule is checked where Use tool is routed, not here.

## Emitted whenever a slot's tool or the selection changes.
signal changed

const SLOT_COUNT: int = 4

## The selected slot, from 0 to SLOT_COUNT - 1. Change it with select().
var selected_index: int = 0

var _slots: Array[HandTool] = []


func _init() -> void:
	_slots.resize(SLOT_COUNT)


## The tool in slot [param index], or null if it's empty or out of range.
func get_tool(index: int) -> HandTool:
	if not _is_valid(index):
		return null
	return _slots[index]


## Puts [param tool] in slot [param index], replacing what was there. Pass
## null to empty it.
func set_tool(index: int, tool: HandTool) -> void:
	if not _is_valid(index):
		push_error("ToolBelt: no slot %d" % index)
		return
	if _slots[index] == tool:
		return
	_slots[index] = tool
	changed.emit()


## The tool in the selected slot, or null if it's empty.
func selected_tool() -> HandTool:
	return _slots[selected_index]


## Selects slot [param index]. Ignores numbers outside the belt.
func select(index: int) -> void:
	if not _is_valid(index) or index == selected_index:
		return
	selected_index = index
	changed.emit()


## Selects the next slot, wrapping from the last back to the first.
func select_next() -> void:
	select(posmod(selected_index + 1, SLOT_COUNT))


## Selects the previous slot, wrapping from the first to the last.
func select_previous() -> void:
	select(posmod(selected_index - 1, SLOT_COUNT))


func _is_valid(index: int) -> bool:
	return index >= 0 and index < SLOT_COUNT
