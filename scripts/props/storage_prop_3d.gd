class_name StorageProp3D
extends StaticBody3D
## A container in 3D: the galley pantry, and later the hold. Interact opens a
## panel to take food out; Use puts the held food away, if it fits here. See
## Storage in docs/GDD.md.
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
## Ingredients the crew keeps in reserve during the first cooking quest.
@export var remedy_reserve: Array[Item] = []

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
	_interactable.used.connect(_on_used)
	_interactable.describe_interact = func(_player: Player3D) -> String:
		return interact_prompt()
	_interactable.describe_use = func(player: Player3D) -> String:
		return use_prompt(player.arms)


## What Interact does: opens the panel to take food out into [param arms].
func open(arms: Arms) -> void:
	_panel.open(display_name, _contents, arms)


## What Use does: puts the held food away, if it fits here. Returns whether
## it did.
func put_away(arms: Arms) -> bool:
	if not _contents.put_away(arms.top()):
		return false
	arms.take_top()
	return true


## The Interact prompt: "Open Pantry".
func interact_prompt() -> String:
	return "Open %s" % display_name


## The Use prompt with [param arms]' held food: "Put away Tomato", or "" if
## it doesn't go here.
func use_prompt(arms: Arms) -> String:
	if _contents.accepts(arms.top()):
		return "Put away %s" % arms.top().item.display_name
	if _can_restock():
		return "Restock soup ingredients"
	return ""


func _can_restock() -> bool:
	return not remedy_reserve.is_empty() and Game.dialogue.is_set(LanternSpirit.LOW_FLAG) \
			and Game.dialogue.is_set(&"read_fire_spirits") and not _contents.is_full()


func _on_interacted(player: Player3D) -> void:
	open(player.arms)


func _on_used(player: Player3D) -> void:
	if put_away(player.arms) or not _can_restock():
		return
	for item: Item in remedy_reserve:
		_contents.add(ItemInstance.new(item))
