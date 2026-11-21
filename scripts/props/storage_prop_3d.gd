class_name StorageProp3D
extends StaticBody3D
## A container in 3D: the galley pantry, and later the hold. Interact puts the
## top of the stack away if it fits here, and otherwise opens a panel to take
## food out. See Storage in docs/GDD.md.
##
## The rules live in [StorageContents]; this node connects it to the player
## and to its [ContainerPanel].

## Shown at the top of the panel.
@export var display_name: String = ""
## The food the player can put away here. A pantry takes any storable food.
@export var kind: Item.StorageKind = Item.StorageKind.PANTRY
## How many pieces fit. 0 means no limit.
@export_range(0, 99) var slots: int = 0
## Food inside when the scene starts, at normal quality.
@export var start_items: Dictionary[Item, int] = {}

## What's inside. Created when the prop is ready, never replaced.
var contents: StorageContents:
	get:
		return _contents

var _contents: StorageContents = null

@onready var _interactable: Interactable3D = $Interactable
@onready var _panel: ContainerPanel = $ContainerPanel


func _ready() -> void:
	_contents = StorageContents.new(kind, slots)
	for item: Item in start_items:
		for i: int in start_items[item]:
			_contents.add(ItemInstance.new(item))
	_interactable.interacted.connect(_on_interacted)


## What Interact does: puts the top of [param arms] away if it fits here, and
## otherwise opens the panel to take food out into [param arms].
func act(arms: Arms) -> void:
	if not _contents.put_away(arms.top()):
		_panel.open(display_name, _contents, arms)
		return
	arms.take_top()


func _on_interacted(player: Player3D) -> void:
	act(player.arms)
