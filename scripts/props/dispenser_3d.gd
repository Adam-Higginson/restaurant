class_name Dispenser3D
extends StaticBody3D
## Gives the player a fresh item on Interact, without limit: the galley's
## plate rack. A model of what it gives sits on top, at its
## [code]ItemSpot[/code] marker.

## Emitted when an item is handed over.
signal dispensed(item: ItemInstance)

## What it gives out, at normal quality.
@export var item: Item = null

@onready var _interactable: Interactable3D = $Interactable
@onready var _item_spot: Node3D = $ItemSpot


func _ready() -> void:
	_interactable.interacted.connect(_on_interacted)
	_interactable.describe_interact = func(player: Player3D) -> String:
		return interact_prompt(player.arms)
	if item != null:
		_item_spot.add_child(ItemModel.build(ItemInstance.new(item)))


## Puts a fresh item on top of [param arms]. Returns false, changing nothing,
## with full arms or nothing to give.
func dispense(arms: Arms) -> bool:
	if item == null or arms.is_full():
		return false
	var instance: ItemInstance = ItemInstance.new(item)
	arms.add(instance)
	dispensed.emit(instance)
	return true


## What [method dispense] would do, for the HUD prompt: "Take Plate", or ""
## with full arms.
func interact_prompt(arms: Arms) -> String:
	if item == null or arms.is_full():
		return ""
	return "Take %s" % item.display_name


func _on_interacted(player: Player3D) -> void:
	dispense(player.arms)
