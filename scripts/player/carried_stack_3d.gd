class_name CarriedStack3D
extends Node3D
## Shows what's selected on the player's toolbar (what they hold) as a small
## model in the hero's left hand, the one the knife doesn't use. Until #206 it
## floated above his head, a leftover from the restaurant game; with no hand to
## hold it (the greybox body), it isn't shown at all.
##
## It turns with the hero (#207). A pot or pan is held by its handle, the
## bowl out in front of the hand; anything else sits in the palm. A tool
## other than the knife (the recipe book) is held the same way; the knife is
## the [Duellist]'s, in the other hand.
##
## Display only: it reads the player's [Arms] and rebuilds when they change,
## or when what's in the held pot changes (filled at the butt).

## How far below the wrist the middle of the palm is, in metres: the item's
## middle sits there, so it's in the hand with the arm hanging.
@export var palm_drop: float = 0.08
## How big the item is in the hand, as a share of its model's size: the
## models are made for a table, a little big for one hand.
@export var held_scale: float = 0.55
## Where a pot's or pan's handle is gripped, along its length from the bowl's
## middle, in the model's own metres (before [member held_scale]).
@export var handle_grip: float = 0.42
## Where a tool held in the hand sits, in the hand bone's own space: the bone
## runs from the wrist along +Y to the knuckles, and the left hand's palm
## faces +X. The book stands along the fingers, its face against the palm,
## its middle just past the knuckles.
@export var tool_grip: Transform3D = Transform3D(Basis(Vector3.UP, PI / 2.0), Vector3(0.04, 0.02, 0.0))
## Where a piece of food sits in the hand, in the hand bone's space: its base
## against the palm (+X), its middle level with the middle of the fingers.
@export var food_grip: Transform3D = Transform3D(Basis(Vector3.BACK, -PI / 2.0), Vector3(0.02, 0.07, 0.0))
## How high the handle is above the pot's base, in the model's own metres.
@export var handle_height: float = 0.12

var _held: ItemInstance = null

@onready var _player: Player3D = get_parent() as Player3D
@onready var _character: CharacterModel = \
		get_node_or_null("../Model/Character") as CharacterModel
@onready var _model: Node3D = get_node_or_null("../Model") as Node3D


func _ready() -> void:
	# Placed by hand every frame, where the hand is drawn: not interpolated.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	scale = Vector3.ONE * held_scale
	# The toolbar is the arms: one signal covers both what's held and which
	# slot is selected.
	_player.arms.changed.connect(_rebuild)
	_rebuild()


func _process(_delta: float) -> void:
	var hand: Node3D = held_in()
	visible = hand != null and get_child_count() > 0 and _character.hold_up <= 0.0
	if hand == null:
		return
	if _held == null or not _held.is_vessel():
		# A tool (the recipe book) or a piece of food moves with the hand
		# itself, swinging as he walks: the book flat against the palm, food
		# resting in it.
		var grip: Transform3D = tool_grip if _held == null else food_grip
		var hand_basis: Basis = hand.global_basis.orthonormalized()
		global_transform = Transform3D(hand_basis, hand.global_position) \
				* Transform3D(grip.basis.scaled(Vector3.ONE * held_scale), grip.origin)
		return
	# Turned the way the hero faces.
	if _model != null:
		global_basis = Basis(Vector3.UP, _model.global_rotation.y).scaled(Vector3.ONE * held_scale)
	if _held != null and _held.is_vessel() and not _held.item.carried_whole \
			and _held.item.vessel_shape != Item.VesselShape.FLAT:
		# By the handle: the handle (+X) points back into the hand, the bowl
		# out in front of it, hanging a little below.
		global_basis = global_basis * Basis(Vector3.UP, deg_to_rad(-90.0))
		global_position = hand.global_position + Vector3.DOWN * palm_drop \
				- global_basis * Vector3(handle_grip, handle_height, 0.0)
		return
	# The model stands on its base: lower it by half its height so its middle
	# is in the palm.
	var half: float = ItemModel.FOOD_SIZE * held_scale / 2.0
	global_position = hand.global_position + Vector3.DOWN * (palm_drop + half)


## The hand the item is held in, or null when there's no hand to hold it
## (the greybox body), so it isn't shown.
func held_in() -> Node3D:
	if _character == null or not is_instance_valid(_character.left_hand):
		return null
	return _character.left_hand


## The model shown now, or null.
func shown() -> Node3D:
	return get_child(0) as Node3D if get_child_count() > 0 else null


# Throws the old model away and builds one of what's held now.
func _rebuild() -> void:
	_watch(_held, false)
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	_held = _player.arms.top()
	if _held != null:
		_watch(_held, true)
		add_child(ItemModel.build(_held))
		return
	var tool: HandTool = _player.toolbar.selected_tool()
	if tool != null and not _is_knife(tool):
		add_child(ItemModel.tool_model(tool))


# Follows what's in a held pot, so filling it shows.
func _watch(item: ItemInstance, watching: bool) -> void:
	if item == null or not item.is_vessel():
		return
	var signal_: Signal = item.contents.contents_changed
	if watching and not signal_.is_connected(_rebuild):
		signal_.connect(_rebuild)
	elif not watching and signal_.is_connected(_rebuild):
		signal_.disconnect(_rebuild)


func _is_knife(tool: HandTool) -> bool:
	return tool.element != null and tool.element.id == &"cut"
