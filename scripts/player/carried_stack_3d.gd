class_name CarriedStack3D
extends Node3D
## Shows the item selected on the player's toolbar (what they hold) as a small
## model in the hero's left hand, the one the knife doesn't use. Until #206 it
## floated above his head, a leftover from the restaurant game; now, with no
## hand to hold it (the greybox body), it isn't shown at all.
##
## Display only: it reads the player's [Arms] and rebuilds when they change.

## How far below the wrist the middle of the palm is, in metres: the item's
## middle sits there, so it's in the hand with the arm hanging.
@export var palm_drop: float = 0.08
## How big the item is in the hand, as a share of its model's size: the
## models are made for a table, a little big for one hand.
@export var held_scale: float = 0.55

@onready var _player: Player3D = get_parent() as Player3D
@onready var _character: CharacterModel = \
		get_node_or_null("../Model/Character") as CharacterModel


func _ready() -> void:
	# Placed by hand every frame, where the hand is drawn: not interpolated.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	scale = Vector3.ONE * held_scale
	_player.arms.changed.connect(_rebuild)
	_rebuild()


func _process(_delta: float) -> void:
	var hand: Node3D = held_in()
	visible = hand != null and get_child_count() > 0
	if hand != null:
		# The model stands on its base: lower it by half its height so its
		# middle is in the palm.
		var half: float = ItemModel.FOOD_SIZE * held_scale / 2.0
		global_position = hand.global_position + Vector3.DOWN * (palm_drop + half)


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
