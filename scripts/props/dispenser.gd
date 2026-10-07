class_name Dispenser
extends StaticBody2D
## Gives the player a fresh item on Interact, without limit: the plate rack,
## and until storage (#32) the temporary lettuce and tomato bins.

## Emitted when an item is handed over.
signal dispensed(item: ItemInstance)

const FRAME_COLOR: Color = Color(0.4, 0.3, 0.22, 1)
const BODY_RECT: Rect2 = Rect2(-8, -8, 16, 16)
const SAMPLE_RECT: Rect2 = Rect2(-4, -4, 8, 8)

## What it gives out, at normal quality.
@export var item: Item = null

@onready var _interactable: Interactable = $Interactable


func _ready() -> void:
	_interactable.interacted.connect(_on_interacted)


func _draw() -> void:
	draw_rect(BODY_RECT, FRAME_COLOR)
	if item != null:
		draw_rect(SAMPLE_RECT, item.color)


## Puts a fresh item on top of [param arms]. Returns false, changing nothing,
## with full arms or nothing to give.
func dispense(arms: Arms) -> bool:
	if item == null or arms.is_full():
		return false
	var instance: ItemInstance = ItemInstance.new(item)
	arms.add(instance)
	dispensed.emit(instance)
	return true


func _on_interacted(player: Player) -> void:
	dispense(player.arms)
