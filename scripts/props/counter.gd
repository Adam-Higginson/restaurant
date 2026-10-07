class_name Counter
extends StaticBody2D
## A kitchen counter. Holds one item, food or a utensil, and swaps it with the
## player's arms on pick up / put down. A vessel on it (a chopping board, a
## plate) takes food from the arms, and Use tool works on what's in it. See
## "Vessels and fittings" in docs/GDD.md.

## Emitted when an item is put on or taken off, with the new item (or null).
## Not emitted when food goes in or out of a vessel on the counter.
signal item_changed(item: ItemInstance)

const COUNTER_COLOR: Color = Color(0.62, 0.6, 0.56, 1)
const COUNTER_RECT: Rect2 = Rect2(-8, -8, 16, 16)
const ITEM_RECT: Rect2 = Rect2(-4, -4, 8, 8)
const VESSEL_RECT: Rect2 = Rect2(-6, -5, 12, 12)
## The progress bar sits along the counter's top edge, above the vessel.
const PROGRESS_RECT: Rect2 = Rect2(-6, -8, 12, 2)

## Something already on the counter when the scene starts.
@export var start_item: Item = null

var _item: ItemInstance = null

@onready var _interactable: Interactable = $Interactable


func _ready() -> void:
	if start_item != null:
		_set_item(ItemInstance.new(start_item))
	_interactable.pick_up_pressed.connect(_on_pick_up_pressed)
	_interactable.tool_used.connect(_on_tool_used)


func _draw() -> void:
	draw_rect(COUNTER_RECT, COUNTER_COLOR)
	if _item == null:
		return
	if _item.is_vessel():
		ItemDraw.draw_item(self, _item, VESSEL_RECT)
		ItemDraw.draw_progress(self, _item.contents, PROGRESS_RECT)
	else:
		ItemDraw.draw_item(self, _item, ITEM_RECT)


## The item on the counter, or null.
func get_item() -> ItemInstance:
	return _item


func is_empty() -> bool:
	return _item == null


## Puts [param item] on the counter. If it's already holding something, changes
## nothing and returns false.
func place(item: ItemInstance) -> bool:
	if item == null:
		push_error("Counter: item is null")
		return false
	if _item != null:
		return false
	_set_item(item)
	return true


## Removes and returns the item, or null if the counter is empty.
func take() -> ItemInstance:
	var item: ItemInstance = _item
	if item != null:
		_set_item(null)
	return item


## Pick up / put down between this counter and [param arms]. Returns whether
## anything moved.
## - Empty counter: the top item goes down here.
## - A vessel here and food on top of the stack: the food goes into the vessel,
##   if it fits.
## - Otherwise, if the arms have room, something comes up onto the stack: the
##   top food from a chopping board, or the whole item (a plate with its food,
##   an empty board, a tomato).
func exchange_with(arms: Arms) -> bool:
	if _item == null:
		if arms.is_empty():
			return false
		return place(arms.take_top())
	var held: ItemInstance = arms.top()
	if _item.is_vessel() and held != null and not held.is_vessel():
		if not _item.contents.add_item(held):
			return false
		arms.take_top()
		return true
	if arms.is_full():
		return false
	if _item.is_vessel() and not _item.item.carried_whole:
		var food: Array[ItemInstance] = _item.contents.get_contents()
		if not food.is_empty():
			var top_food: ItemInstance = food[food.size() - 1]
			_item.contents.remove_item(top_food)
			return arms.add(top_food)
	return arms.add(take())


## Uses [param tool] on what's on the counter: the knife cuts food on a board.
## Returns whether it did anything; it doesn't without a vessel or with
## nothing the tool can work on.
func use_tool(tool: HandTool) -> bool:
	if _item == null or not _item.is_vessel() or tool.element == null:
		return false
	return _item.contents.add_element(tool.element)


func _set_item(item: ItemInstance) -> void:
	if _item != null and _item.is_vessel():
		_watch(_item.contents, false)
	_item = item
	if _item != null and _item.is_vessel():
		_watch(_item.contents, true)
	queue_redraw()
	item_changed.emit(_item)


# Redraws while a vessel is here. Disconnected when it leaves, so a carried
# board doesn't keep redrawing a counter it's no longer on.
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
	queue_redraw()


func _on_pick_up_pressed(player: Player) -> void:
	exchange_with(player.arms)


func _on_tool_used(_player: Player, tool: HandTool) -> void:
	use_tool(tool)
