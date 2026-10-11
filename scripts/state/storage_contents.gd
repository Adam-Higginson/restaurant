class_name StorageContents
extends RefCounted
## What's inside one container (the fridge, the cupboard, the delivery crate):
## a list of food, one piece per slot, each keeping its quality.
##
## Doesn't know where the food came from: the shop fills the crate today, and
## farms will later. See Storage in docs/GDD.md.

## Emitted whenever food goes in or comes out.
signal changed

## How many pieces fit. 0 means no limit (the crate).
var capacity: int:
	get:
		return _capacity
	set(_value):
		push_error("StorageContents: capacity is read-only")
## The kind of food the player can put away here.
var kind: Item.StorageKind:
	get:
		return _kind
	set(_value):
		push_error("StorageContents: kind is read-only")
## Whether the player can only take from it (the crate).
var take_only: bool:
	get:
		return _take_only
	set(_value):
		push_error("StorageContents: take_only is read-only")

var _capacity: int = 0
var _kind: Item.StorageKind = Item.StorageKind.NONE
var _take_only: bool = false
var _items: Array[ItemInstance] = []


func _init(storage_kind: Item.StorageKind, slots: int = 0, is_take_only: bool = false) -> void:
	_kind = storage_kind
	_capacity = maxi(slots, 0)
	_take_only = is_take_only


## The food inside, oldest first. Changing the copy doesn't change the container.
func get_items() -> Array[ItemInstance]:
	return _items.duplicate()


func size() -> int:
	return _items.size()


func is_empty() -> bool:
	return _items.is_empty()


func is_full() -> bool:
	return _capacity > 0 and _items.size() >= _capacity


## How many pieces of [param item] at [param quality] are inside.
func count(item: Item, quality: int) -> int:
	var total: int = 0
	for piece: ItemInstance in _items:
		if piece.item == item and piece.quality == quality:
			total += 1
	return total


## Whether the player could put [param instance] away here: food of this
## container's kind, with room left, and never into a take-only container.
func accepts(instance: ItemInstance) -> bool:
	if instance == null or _take_only or is_full():
		return false
	if instance.is_vessel():
		return false
	return _kind != Item.StorageKind.NONE and instance.item.storage == _kind


## Puts [param instance] away if [method accepts] allows it. Returns whether it did.
func put_away(instance: ItemInstance) -> bool:
	if not accepts(instance):
		return false
	_items.append(instance)
	changed.emit()
	return true


## Adds [param instance] whatever its kind, even to a take-only container: how
## deliveries arrive. Still refused when full. Returns whether it was added.
func add(instance: ItemInstance) -> bool:
	if instance == null:
		push_error("StorageContents: instance is null")
		return false
	if is_full():
		return false
	_items.append(instance)
	changed.emit()
	return true


## Removes and returns the oldest piece of [param item] at [param quality], or
## null if there isn't one.
func take(item: Item, quality: int) -> ItemInstance:
	for i: int in _items.size():
		var piece: ItemInstance = _items[i]
		if piece.item == item and piece.quality == quality:
			_items.remove_at(i)
			changed.emit()
			return piece
	return null


## Moves the oldest piece of [param item] at [param quality] onto [param arms].
## Returns false, changing nothing, with full arms or none inside.
func take_into(arms: Arms, item: Item, quality: int) -> bool:
	if arms.is_full() or count(item, quality) == 0:
		return false
	return arms.add(take(item, quality))
