class_name Arms
extends RefCounted
## The items the player carries above their head. The 3D player carries one
## item at a time; the legacy 2D player carries a stack of three.
##
## The last item in the stack is the top one, and only the top one is active:
## putting down uses it and anything picked up goes on top. See the Player
## section of docs/GDD.md.

## Emitted whenever the stack's contents or order change.
signal changed

## How many items the legacy 2D player's stack holds, the default.
const CAPACITY: int = 3

## How many items fit.
var capacity: int:
	get:
		return _capacity
	set(_value):
		push_error("Arms: capacity is read-only")

var _capacity: int = CAPACITY
var _items: Array[ItemInstance] = []


func _init(max_items: int = CAPACITY) -> void:
	_capacity = maxi(max_items, 1)


## The carried items, bottom first. Changing the copy doesn't change the arms.
func get_items() -> Array[ItemInstance]:
	return _items.duplicate()


func size() -> int:
	return _items.size()


func is_empty() -> bool:
	return _items.is_empty()


func is_full() -> bool:
	return _items.size() >= _capacity


## The active item, or null with empty arms.
func top() -> ItemInstance:
	return null if _items.is_empty() else _items.back()


## Puts [param item] on top of the stack. With full arms, changes nothing and
## returns false.
func add(item: ItemInstance) -> bool:
	if item == null:
		push_error("Arms: item is null")
		return false
	if is_full():
		return false
	_items.append(item)
	changed.emit()
	return true


## Removes and returns the top item, or null with empty arms.
func take_top() -> ItemInstance:
	if _items.is_empty():
		return null
	var item: ItemInstance = _items.pop_back()
	changed.emit()
	return item


## Moves the top item to the bottom, so the one below it becomes active.
## Does nothing with fewer than two items.
func rotate() -> void:
	if _items.size() < 2:
		return
	_items.push_front(_items.pop_back())
	changed.emit()
