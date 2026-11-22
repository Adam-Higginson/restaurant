class_name WaterButt
extends Node3D
## The open water butt on deck, brimming with rain. Holding a saucepan (or
## any vessel with room), Interact to fill it with rainwater, for boiling
## below. The storm keeps it full.

## What it gives.
@export var water: Item

@onready var _reach: Interactable3D = $Reach


func _ready() -> void:
	_reach.interacted.connect(func(player: Player3D) -> void: fill(player.arms))
	_reach.describe_interact = func(player: Player3D) -> String: return prompt(player.arms)


## Whether [param arms] hold something it could pour water into.
func can_fill(arms: Arms) -> bool:
	var held: ItemInstance = arms.top()
	return water != null and held != null and held.is_vessel() \
			and not held.item.carried_whole and held.contents.room() > 0


## Pours rainwater into the held vessel. Returns whether it did.
func fill(arms: Arms) -> bool:
	if not can_fill(arms):
		return false
	return arms.top().contents.add_item(ItemInstance.new(water))


## What Interact would do, for the HUD: "Fill Saucepan with rainwater", or "".
func prompt(arms: Arms) -> String:
	if not can_fill(arms):
		return ""
	return "Fill %s with rainwater" % arms.top().item.display_name
