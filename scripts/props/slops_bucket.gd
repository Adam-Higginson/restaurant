extends Node3D
## A place to discard a batch and keep its vessel.

@onready var _reach: Interactable3D = $Reach


func _ready() -> void:
	_reach.describe_use = _prompt
	_reach.used.connect(_empty)


func _prompt(player: Player3D) -> String:
	var vessel: ItemInstance = player.arms.top()
	if vessel == null or not vessel.is_vessel() or vessel.contents.get_contents().is_empty():
		return ""
	return "Empty %s" % vessel.item.display_name


func _empty(player: Player3D) -> void:
	if _prompt(player).is_empty():
		return
	var contents: VesselContents = player.arms.top().contents
	for food: ItemInstance in contents.get_contents():
		contents.remove_item(food)
