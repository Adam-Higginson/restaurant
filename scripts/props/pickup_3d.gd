class_name Pickup3D
extends Node3D
## Something lying loose on the ground to pick up, like the meat a crab
## leaves behind. Interact picks it up onto the toolbar ("Pick up Crab Meat
## ★"); with the toolbar full it stays where it lies.
##
## Its scene ([constant SCENE_PATH]) has an [Interactable3D] for the player's
## detector to find. The item's greybox model is built from the item in code.

## Emitted when the player picks it up, just before it's gone.
signal picked_up(item: ItemInstance)

## Loaded when needed rather than preloaded: the scene uses this script, and
## a script preloading its own scene is a loop.
const SCENE_PATH: String = "res://scenes/props/pickup.tscn"

## What's lying here.
var item: ItemInstance = null

@onready var _interactable: Interactable3D = $Interactable


## Lays [param what] on the ground at [param at], as a child of [param parent].
static func spawn(parent: Node, at: Vector3, what: ItemInstance) -> Pickup3D:
	var pickup: Pickup3D = (load(SCENE_PATH) as PackedScene).instantiate() as Pickup3D
	pickup.item = what
	parent.add_child(pickup)
	pickup.global_position = at
	return pickup


func _ready() -> void:
	if item != null:
		add_child(ItemModel.build(item))
	_interactable.describe_interact = prompt
	_interactable.interacted.connect(pick_up)


## What Interact would do for [param player]: "Pick up Crab Meat ★".
func prompt(_player: Player3D) -> String:
	if item == null:
		return ""
	return "Pick up %s %s" % [item.item.display_name, "★".repeat(item.quality)]


## Puts it on [param player]'s toolbar and takes it off the ground. Returns
## whether it fitted.
func pick_up(player: Player3D) -> bool:
	if item == null or not player.toolbar.add(item):
		return false
	picked_up.emit(item)
	item = null
	queue_free()
	return true
