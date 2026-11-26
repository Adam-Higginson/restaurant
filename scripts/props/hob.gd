class_name Hob
extends Counter3D
## A place on the galley hearth's hot iron top, over the fire. It works like a
## counter (put a pan down, put food in it, take it off), and whatever vessel
## sits here is heated: it has [member heat] (fire) for as long as it stays,
## so fire recipes cook in it, second by second. Take the pan off and the
## cooking pauses, keeping its progress, until it goes back on.

## The timed element this provides: fire.
@export var heat: Element

## The vessel being heated now, or null.
var heated: ItemInstance:
	get:
		return _heated

var _heated: ItemInstance = null


func _ready() -> void:
	super()
	slot.item_changed.connect(_on_item_changed)
	slot.food_made.connect(_remember_remedy)
	_on_item_changed(slot.get_item())


func _physics_process(delta: float) -> void:
	if _heated != null:
		_heated.contents.tick(delta)


func _remember_remedy(food: ItemInstance) -> void:
	if food.item.id == &"spicy_tomato_soup":
		Game.dialogue.set_flag(&"cooked_remedy")


func _on_item_changed(item: ItemInstance) -> void:
	if _heated != null:
		_heated.contents.remove_element(heat)
	_heated = item if item != null and item.is_vessel() else null
	if _heated != null:
		_heated.contents.add_element(heat)
