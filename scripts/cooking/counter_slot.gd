class_name CounterSlot
extends RefCounted
## The spot on a counter that holds one item, food or a utensil, and swaps it
## with the player's arms on Interact. A vessel here (a chopping board, a
## plate) takes food from the arms, and Use tool works on what's in it. See
## "Vessels and fittings" in docs/GDD.md.
##
## Plain logic with no node, so any counter (the 3D galley's for now) can
## wrap one, and its rules are tested without a running scene.

## Emitted when an item is put on or taken off, with the new item (or null).
## Not emitted when food goes in or out of a vessel here.
signal item_changed(item: ItemInstance)
## Emitted whenever anything that shows changes: the item, the food in a
## vessel here, or a reaction's progress. Views redraw on it.
signal changed

## What Interact would do here. See [method interact_action].
enum Action {
	## Nothing: E is hidden in the prompt.
	NONE,
	## Put the held item down on the empty counter.
	PUT_DOWN,
	## Put the held food into the vessel here (a board or plate).
	ADD_TO_VESSEL,
	## Slide the food from the board here onto the held plate or bowl.
	MOVE_ONTO_PLATE,
	## Take the top food off the board here.
	TAKE_FOOD,
	## Pick up the whole item here.
	PICK_UP,
}

var _item: ItemInstance = null


func _init(start_item: Item = null) -> void:
	if start_item != null:
		_set_item(ItemInstance.new(start_item))


## The item here, or null.
func get_item() -> ItemInstance:
	return _item


func is_empty() -> bool:
	return _item == null


## Puts [param item] here. If it's already holding something, changes nothing
## and returns false.
func place(item: ItemInstance) -> bool:
	if item == null:
		push_error("CounterSlot: item is null")
		return false
	if _item != null:
		return false
	_set_item(item)
	return true


## Removes and returns the item, or null if it's empty.
func take() -> ItemInstance:
	var item: ItemInstance = _item
	if item != null:
		_set_item(null)
	return item


## What Interact would do between here and [param arms], without doing it.
## [method exchange_with] does exactly this, so the HUD prompt and the game
## never disagree.
## - Empty: the held item goes down here.
## - A vessel here and food held: the food goes into the vessel, if it fits.
## - A plate or bowl held, at a board with food: the food slides onto the
##   plate, if it all fits.
## - Otherwise, with free hands, something comes up: the top food from a
##   board, or the whole item (a plate with its food, an empty board, a tomato).
func interact_action(arms: Arms) -> Action:
	var held: ItemInstance = arms.top()
	if _item == null:
		return Action.NONE if held == null else Action.PUT_DOWN
	if _item.is_vessel() and held != null and not held.is_vessel():
		return Action.ADD_TO_VESSEL if _item.contents.room() > 0 else Action.NONE
	if _can_move_onto(held):
		return Action.MOVE_ONTO_PLATE
	if arms.is_full():
		return Action.NONE
	if _board_food() != null:
		return Action.TAKE_FOOD
	return Action.PICK_UP


## Does what [method interact_action] says. Returns whether anything moved.
func exchange_with(arms: Arms) -> bool:
	match interact_action(arms):
		Action.PUT_DOWN:
			return place(arms.take_top())
		Action.ADD_TO_VESSEL:
			if not _item.contents.add_item(arms.top()):
				return false
			arms.take_top()
			return true
		Action.MOVE_ONTO_PLATE:
			var plate: VesselContents = arms.top().contents
			for food: ItemInstance in _item.contents.get_contents():
				_item.contents.remove_item(food)
				plate.add_item(food)
			return true
		Action.TAKE_FOOD:
			var food: ItemInstance = _board_food()
			_item.contents.remove_item(food)
			return arms.add(food)
		Action.PICK_UP:
			return arms.add(take())
	return false


## What the prompt says Interact would do, e.g. "Put down Tomato", or "" for
## nothing.
func interact_prompt(arms: Arms) -> String:
	var held: ItemInstance = arms.top()
	match interact_action(arms):
		Action.PUT_DOWN:
			return "Put down %s" % held.item.display_name
		Action.ADD_TO_VESSEL:
			return "Put %s on %s" % [held.item.display_name, _item.item.display_name]
		Action.MOVE_ONTO_PLATE:
			var food: Array[ItemInstance] = _item.contents.get_contents()
			var what: String = food[0].item.display_name if food.size() == 1 else "food"
			return "Put %s on %s" % [what, held.item.display_name]
		Action.TAKE_FOOD:
			return "Take %s" % _board_food().item.display_name
		Action.PICK_UP:
			return "Pick up %s" % _item.item.display_name
	return ""


## Whether [param tool] would do anything here: the knife cuts food on a board
## until it can't be cut any further.
func can_use_tool(tool: HandTool) -> bool:
	if _item == null or not _item.is_vessel() or tool.element == null:
		return false
	return _item.contents.would_react_to(tool.element)


## Uses [param tool] on what's here: the knife cuts food on a board. Returns
## whether it did anything; it doesn't without a vessel or with nothing the
## tool can work on.
func use_tool(tool: HandTool) -> bool:
	if _item == null or not _item.is_vessel() or tool.element == null:
		return false
	return _item.contents.add_element(tool.element)


# The top food on a board here (a vessel not carried whole), or null.
func _board_food() -> ItemInstance:
	if _item == null or not _item.is_vessel() or _item.item.carried_whole:
		return null
	var food: Array[ItemInstance] = _item.contents.get_contents()
	return null if food.is_empty() else food[food.size() - 1]


# Whether the food on a board here could all slide onto [param held], a plate
# or bowl.
func _can_move_onto(held: ItemInstance) -> bool:
	if held == null or not held.is_vessel() or not held.item.carried_whole:
		return false
	if _item == null or not _item.is_vessel() or _item.item.carried_whole:
		return false
	var count: int = _item.contents.get_contents().size()
	return count > 0 and held.contents.room() >= count


func _set_item(item: ItemInstance) -> void:
	if _item != null and _item.is_vessel():
		_watch(_item.contents, false)
	_item = item
	if _item != null and _item.is_vessel():
		_watch(_item.contents, true)
	item_changed.emit(_item)
	changed.emit()


# Passes on a vessel's changes while it's here. Disconnected when it leaves,
# so a carried board doesn't keep updating a counter it's no longer on.
func _watch(contents: VesselContents, watching: bool) -> void:
	var signals: Array[Signal] = [
		contents.contents_changed, contents.reaction_started,
		contents.reaction_progressed, contents.reaction_cancelled,
	]
	for vessel_signal: Signal in signals:
		if watching:
			vessel_signal.connect(_on_vessel_changed)
		else:
			vessel_signal.disconnect(_on_vessel_changed)


# Takes the signals' arguments, if any, and ignores them.
func _on_vessel_changed(_active: ActiveReaction = null) -> void:
	changed.emit()
