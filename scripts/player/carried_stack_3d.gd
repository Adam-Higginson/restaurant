class_name CarriedStack3D
extends Node3D
## Shows the item selected on the player's toolbar (what they hold) as a small
## model in the hero's left hand, the one the knife doesn't use. Until #206 it
## floated above his head, a leftover from the restaurant game; now, with no
## hand to hold it (the greybox body), it isn't shown at all.
##
## Display only: it reads the player's [Arms] and rebuilds when they change.

## Where the item sits from the hand bone, in the hand's own space: a little
## below the palm, so it's held rather than skewered.
@export var grip_offset: Vector3 = Vector3(0.0, -0.06, 0.03)

@onready var _player: Player3D = get_parent() as Player3D
@onready var _character: CharacterModel = \
		get_node_or_null("../Model/Character") as CharacterModel


func _ready() -> void:
	# Placed by hand every frame, where the hand is drawn: not interpolated.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_player.arms.changed.connect(_rebuild)
	_rebuild()


func _process(_delta: float) -> void:
	var hand: Node3D = held_in()
	visible = hand != null and get_child_count() > 0
	if hand != null:
		global_position = hand.global_transform * grip_offset


## The hand the item is held in, or null when there's no hand to hold it
## (the greybox body), so it isn't shown.
func held_in() -> Node3D:
	if _character == null or not is_instance_valid(_character.left_hand):
		return null
	return _character.left_hand


# Throws the old model away and builds one of what's held now.
func _rebuild() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	var item: ItemInstance = _player.arms.top()
	if item != null:
		add_child(ItemModel.build(item))
