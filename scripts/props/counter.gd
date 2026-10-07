class_name Counter
extends StaticBody2D
## A kitchen counter. Holds one item, food or a utensil, and swaps it with the
## player's arms on pick up / put down. See "Vessels and fittings" in docs/GDD.md.

## Emitted when an item is put on or taken off, with the new item (or null).
signal item_changed(item: ItemInstance)

const COUNTER_COLOR: Color = Color(0.62, 0.6, 0.56, 1)
const COUNTER_RECT: Rect2 = Rect2(-8, -8, 16, 16)
const ITEM_RECT: Rect2 = Rect2(-4, -4, 8, 8)

## Something already on the counter when the scene starts.
@export var start_item: Item = null

var _item: ItemInstance = null

@onready var _interactable: Interactable = $Interactable


func _ready() -> void:
	if start_item != null:
		_item = ItemInstance.new(start_item)
	_interactable.pick_up_pressed.connect(_on_pick_up_pressed)


func _draw() -> void:
	draw_rect(COUNTER_RECT, COUNTER_COLOR)
	if _item != null:
		draw_rect(ITEM_RECT, _item.item.color)


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


## Pick up / put down between this counter and [param arms]: takes the item onto
## the top of the stack, or puts the top item down here. Returns whether
## anything moved; it doesn't with full arms or nothing to move.
func exchange_with(arms: Arms) -> bool:
	if _item != null:
		if arms.is_full():
			return false
		return arms.add(take())
	if arms.is_empty():
		return false
	return place(arms.take_top())


func _set_item(item: ItemInstance) -> void:
	_item = item
	queue_redraw()
	item_changed.emit(_item)


func _on_pick_up_pressed(player: Player) -> void:
	exchange_with(player.arms)
