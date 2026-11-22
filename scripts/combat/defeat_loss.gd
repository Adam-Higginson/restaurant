class_name DefeatLoss
extends RefCounted
## What a defeat costs: half of what you carry. Tools (the knife) are never
## lost. Of the items, half go, rounded down, taken from the highest-numbered
## slots first, so which ones is never a surprise. See Combat in docs/GDD.md.


## How many of [param carried] items a defeat takes: half, rounded down.
static func count_lost(carried: int) -> int:
	@warning_ignore("integer_division")
	return maxi(carried, 0) / 2


## Takes half of [param toolbar]'s items off it and returns them, last slot
## first. Tools stay where they are.
static func take_half(toolbar: Toolbar) -> Array[ItemInstance]:
	var lost: Array[ItemInstance] = []
	var to_lose: int = count_lost(toolbar.size())
	for slot: int in range(Toolbar.SLOT_COUNT - 1, -1, -1):
		if lost.size() >= to_lose:
			break
		var item: ItemInstance = toolbar.take_item(slot)
		if item != null:
			lost.append(item)
	return lost
