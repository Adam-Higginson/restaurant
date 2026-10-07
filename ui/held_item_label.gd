class_name HeldItemLabel
extends Label
## Names the player's active (top) carried item and its quality, e.g.
## "Sliced Tomato ★★", or "Plate: Garden Salad ★★★" for a plate. Empty with
## empty arms.
##
## Display only: it reads the player's [Arms] and updates when they change.

## The player whose arms this shows. Set in the scene.
@export var player: Player


func _ready() -> void:
	player.arms.changed.connect(_update)
	_update()


## The text shown for [param instance]. Vessels show their food rather than
## their own quality.
static func describe(instance: ItemInstance) -> String:
	if not instance.is_vessel():
		return "%s %s" % [instance.item.display_name, "★".repeat(instance.quality)]
	var food: Array[ItemInstance] = instance.contents.get_contents()
	if food.is_empty():
		return instance.item.display_name
	var names: PackedStringArray = []
	for piece: ItemInstance in food:
		names.append(describe(piece))
	return "%s: %s" % [instance.item.display_name, ", ".join(names)]


func _update() -> void:
	var top: ItemInstance = player.arms.top()
	text = "" if top == null else describe(top)
