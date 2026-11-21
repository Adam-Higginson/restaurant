class_name InteractionDetector3D
extends Area3D
## Sits in front of the player, focuses the nearest enabled [Interactable3D]
## it overlaps, and sends it "interact" and "use_tool" presses. A small arrow
## floats over whatever is focused, so you can see what Interact would use.

## Emitted when the focused interactable changes (null when nothing is in reach).
signal focus_changed(interactable: Interactable3D)

## How far in front of the player's centre the detection zone sits, in metres.
@export var reach: float = 0.7
## How high above the player's feet the detection zone sits, in metres:
## about counter height.
@export var height: float = 0.9
## How far the focus arrow bobs up and down, in metres.
@export var arrow_bob_height: float = 0.06
## Arrow bobs per second.
@export var arrow_bob_rate: float = 1.5

## The interactable that "interact" would use right now, or null.
var focused: Interactable3D = null

var _bob_time: float = 0.0

@onready var _player: Player3D = get_parent() as Player3D
@onready var _arrow: Node3D = $FocusArrow


func _ready() -> void:
	collision_layer = 0
	collision_mask = Interactable3D.LAYER
	monitoring = true
	monitorable = false
	_arrow.hide()


func _physics_process(_delta: float) -> void:
	# The player's body never turns (only its model does), so a local offset
	# along the facing is the same as a world one.
	position = _player.facing * reach + Vector3.UP * height
	_update_focus()


func _process(delta: float) -> void:
	_bob_time += delta
	_place_arrow()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		try_interact()
	elif event.is_action_pressed("use_tool"):
		get_viewport().set_input_as_handled()
		try_use_tool()


## Uses the focused interactable, if any. Returns whether something was used.
func try_interact() -> bool:
	if not is_instance_valid(focused):
		return false
	focused.interact(_player)
	return true


## Uses the selected belt tool on the focused interactable. Tools only work
## with empty arms, so this does nothing while carrying, with an empty slot
## selected, or with nothing in reach. Returns whether the tool was used.
func try_use_tool() -> bool:
	var tool: HandTool = _player.belt.selected_tool()
	if tool == null or not _player.arms.is_empty() or not is_instance_valid(focused):
		return false
	focused.use_tool(_player, tool)
	return true


func _update_focus() -> void:
	var best: Interactable3D = null
	var best_distance: float = INF
	for area: Area3D in get_overlapping_areas():
		var candidate: Interactable3D = area as Interactable3D
		if candidate == null or not candidate.enabled:
			continue
		var distance: float = global_position.distance_squared_to(candidate.global_position)
		if distance < best_distance:
			best = candidate
			best_distance = distance
	if best == focused:
		return
	focused = best
	focus_changed.emit(focused)


# Floats the arrow over the focused interactable, bobbing gently, or hides it.
func _place_arrow() -> void:
	if not is_instance_valid(focused):
		_arrow.hide()
		return
	_arrow.show()
	# Where the interactable is drawn this frame, so the arrow rides the
	# sailing ship smoothly.
	var above: Vector3 = focused.get_global_transform_interpolated().origin \
			+ Vector3.UP * focused.focus_height
	var bob: float = sin(_bob_time * arrow_bob_rate * TAU) * arrow_bob_height
	_arrow.global_position = above + Vector3.UP * bob
