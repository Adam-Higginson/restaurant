class_name Counter3D
extends StaticBody3D
## A galley counter in 3D. Holds one item, food or a utensil, and swaps it with
## the player's arms on Interact. With a chopping board on it, Use tool (the
## knife) cuts the food on the board.
##
## The rules live in [CounterSlot]; this node connects it to the player and
## shows what's on it, at its [code]ItemSpot[/code] marker.

## Something already on the counter when the scene starts (the galley's
## chopping board).
@export var start_item: Item = null

## What's on the counter. Created when the counter is ready, never replaced.
var slot: CounterSlot:
	get:
		return _slot

var _slot: CounterSlot = null

@onready var _interactable: Interactable3D = $Interactable
@onready var _item_spot: Node3D = $ItemSpot


func _ready() -> void:
	_slot = CounterSlot.new(start_item)
	_slot.changed.connect(_show_item)
	_interactable.interacted.connect(_on_interacted)
	_interactable.tool_used.connect(_on_tool_used)
	_show_item()


# Swaps the old model for one of what's here now.
func _show_item() -> void:
	for child: Node in _item_spot.get_children():
		# Out of the tree now, not at the end of the frame, so there's never
		# an old and a new model at once.
		_item_spot.remove_child(child)
		child.queue_free()
	var item: ItemInstance = _slot.get_item()
	if item != null:
		_item_spot.add_child(ItemModel.build(item))


func _on_interacted(player: Player3D) -> void:
	_slot.exchange_with(player.arms)


func _on_tool_used(_player: Player3D, tool: HandTool) -> void:
	_slot.use_tool(tool)
