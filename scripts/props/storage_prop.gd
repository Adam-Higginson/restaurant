class_name StorageProp
extends StaticBody2D
## A container in the restaurant: the fridge, the cupboard or the delivery
## crate. Put down puts the top of the stack away if it fits, and Interact
## opens a panel to take food out. See Storage in docs/GDD.md.

const LID_COLOR: Color = Color(1, 1, 1, 0.25)
## A strip along the top edge marks it as a container rather than a counter.
const LID_HEIGHT: float = 3.0

## Shown at the top of the panel.
@export var display_name: String = ""
## The food the player can put away here. Ignored when [member take_only].
@export var kind: Item.StorageKind = Item.StorageKind.NONE
## How many pieces fit. 0 means no limit.
@export_range(0, 99) var slots: int = 0
## Whether the player can only take from it (the delivery crate).
@export var take_only: bool = false
## Placeholder colour until there's real art.
@export var color: Color = Color.WHITE
## Food inside when the scene starts, at normal quality: the day-one starter
## delivery in the crate.
@export var start_items: Dictionary[Item, int] = {}
## The body's size, centred on the node.
@export var size: Vector2 = Vector2(16, 16)

## What's inside. Created when the prop enters the scene, never replaced.
var contents: StorageContents:
	get:
		return _contents
	set(_value):
		push_error("StorageProp: contents can't be replaced")

var _contents: StorageContents = null

@onready var _interactable: Interactable = $Interactable
@onready var _panel: ContainerPanel = $ContainerPanel


func _ready() -> void:
	_contents = StorageContents.new(kind, slots, take_only)
	for item: Item in start_items:
		for i: int in start_items[item]:
			_contents.add(ItemInstance.new(item))
	_interactable.interacted.connect(_on_interacted)
	_interactable.pick_up_pressed.connect(_on_pick_up_pressed)


func _draw() -> void:
	var body: Rect2 = Rect2(-size / 2.0, size)
	draw_rect(body, color)
	draw_rect(Rect2(body.position, Vector2(size.x, LID_HEIGHT)), LID_COLOR)


## Puts the top of [param arms] away if this container accepts it. Returns
## whether it did; otherwise the item stays in the arms.
func put_away_from(arms: Arms) -> bool:
	if not _contents.accepts(arms.top()):
		return false
	return _contents.put_away(arms.take_top())


## Opens the panel for taking food out into [param arms].
func open_for(arms: Arms) -> void:
	_panel.open(display_name, _contents, arms)


func _on_interacted(player: Player) -> void:
	open_for(player.arms)


func _on_pick_up_pressed(player: Player) -> void:
	put_away_from(player.arms)
