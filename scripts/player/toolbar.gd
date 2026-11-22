class_name Toolbar
extends Arms
## The 3D player's toolbar, as in Stardew Valley: a row of slots holding hand
## tools and items together, with one slot selected. The selected slot is what
## the player holds: an item there shows above their head, and Interact uses
## it. Picking something up puts it in the first free slot and selects it.
## See the Player section of docs/GDD.md.
##
## It extends [Arms] so every rule written for arms (counters, the pantry,
## the plate rack, the container panel) works with it unchanged:
## [method top] is the selected item, [method add] fills the first free slot,
## [method take_top] empties the selected slot, and [method is_full] means no
## slot is free. Arms' own stack is never used.

const SLOT_COUNT: int = 12

## The selected slot, from 0 to SLOT_COUNT - 1. Change it with select().
var selected_index: int:
	get:
		return _selected

var _selected: int = 0
## Each slot holds a tool, an item, or neither; never both.
var _tools: Array[HandTool] = []
var _slot_items: Array[ItemInstance] = []


func _init() -> void:
	_tools.resize(SLOT_COUNT)
	_slot_items.resize(SLOT_COUNT)


## The items on the toolbar, in slot order.
func get_items() -> Array[ItemInstance]:
	var items: Array[ItemInstance] = []
	for item: ItemInstance in _slot_items:
		if item != null:
			items.append(item)
	return items


## How many items are on the toolbar. Tools don't count.
func size() -> int:
	return get_items().size()


## Whether no items are on the toolbar (there may still be tools).
func is_empty() -> bool:
	return size() == 0


## Whether every slot holds a tool or an item, so nothing more can be picked up.
func is_full() -> bool:
	return _free_slot() == -1


## The selected item: what the player holds. Null if the selected slot is
## empty or holds a tool.
func top() -> ItemInstance:
	return _slot_items[_selected]


## Puts [param item] in the first free slot and selects it. With no free slot,
## changes nothing and returns false.
func add(item: ItemInstance) -> bool:
	if item == null:
		push_error("Toolbar: item is null")
		return false
	var slot: int = _free_slot()
	if slot == -1:
		return false
	_slot_items[slot] = item
	_selected = slot
	changed.emit()
	return true


## Removes and returns the selected item, or null if none is selected. The
## slot stays selected, now empty.
func take_top() -> ItemInstance:
	var item: ItemInstance = _slot_items[_selected]
	if item == null:
		return null
	_slot_items[_selected] = null
	changed.emit()
	return item


## Removes and returns the item in slot [param index], whichever slot is
## selected, or null if there's none there.
func take_item(index: int) -> ItemInstance:
	var item: ItemInstance = get_item(index)
	if item == null:
		return null
	_slot_items[index] = null
	changed.emit()
	return item


## Whether any slot holds an item of the kind with this [param id]
## (e.g. &"frying_pan"), selected or not.
func has_item(id: StringName) -> bool:
	for item: ItemInstance in _slot_items:
		if item != null and item.item.id == id:
			return true
	return false


## The toolbar has no stack to rotate; select a slot instead.
func rotate() -> void:
	pass


## The tool in slot [param index], or null.
func get_tool(index: int) -> HandTool:
	return _tools[index] if _is_valid(index) else null


## The item in slot [param index], or null.
func get_item(index: int) -> ItemInstance:
	return _slot_items[index] if _is_valid(index) else null


## Puts [param tool] in slot [param index], replacing any tool there. Pass
## null to empty it. Refused if the slot holds an item.
func set_tool(index: int, tool: HandTool) -> void:
	if not _is_valid(index):
		push_error("Toolbar: no slot %d" % index)
		return
	if _slot_items[index] != null:
		push_error("Toolbar: slot %d holds an item" % index)
		return
	if _tools[index] == tool:
		return
	_tools[index] = tool
	changed.emit()


## The tool in the selected slot, or null.
func selected_tool() -> HandTool:
	return _tools[_selected]


## Every tool on the toolbar, in slot order.
func get_tools() -> Array[HandTool]:
	var tools: Array[HandTool] = []
	for tool: HandTool in _tools:
		if tool != null:
			tools.append(tool)
	return tools


## Selects slot [param index]. Ignores numbers outside the toolbar.
func select(index: int) -> void:
	if not _is_valid(index) or index == _selected:
		return
	_selected = index
	changed.emit()


## Selects the next slot, wrapping from the last back to the first.
func select_next() -> void:
	select(posmod(_selected + 1, SLOT_COUNT))


## Selects the previous slot, wrapping from the first to the last.
func select_previous() -> void:
	select(posmod(_selected - 1, SLOT_COUNT))


# The first slot with neither a tool nor an item, or -1.
func _free_slot() -> int:
	for i: int in SLOT_COUNT:
		if _tools[i] == null and _slot_items[i] == null:
			return i
	return -1


func _is_valid(index: int) -> bool:
	return index >= 0 and index < SLOT_COUNT
