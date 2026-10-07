class_name InteractionDetector
extends Area2D
## Sits in front of the player, focuses the nearest enabled Interactable it
## overlaps, and sends it "interact", "pick_up" and "use_tool" presses.

## Emitted when the focused interactable changes (null when nothing is in reach).
signal focus_changed(interactable: Interactable)

## How far in front of the player's centre the detection zone sits, in pixels.
@export var reach: float = 12.0

## The interactable that "interact" would use right now, or null.
var focused: Interactable = null

@onready var _player: Player = get_parent() as Player


func _ready() -> void:
	collision_layer = 0
	collision_mask = Interactable.LAYER
	monitoring = true
	monitorable = false


func _physics_process(_delta: float) -> void:
	position = _player.facing * reach
	_update_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		try_interact()
	elif event.is_action_pressed("pick_up"):
		get_viewport().set_input_as_handled()
		try_pick_up()
	elif event.is_action_pressed("use_tool"):
		get_viewport().set_input_as_handled()
		try_use_tool()


## Uses the focused interactable, if any. Returns whether something was used.
func try_interact() -> bool:
	if not is_instance_valid(focused):
		return false
	focused.interact(_player)
	return true


## Picks up from or puts down at the focused interactable, if any. Returns
## whether there was something to send it to.
func try_pick_up() -> bool:
	if not is_instance_valid(focused):
		return false
	focused.pick_up(_player)
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
	var best: Interactable = null
	var best_distance: float = INF
	for area: Area2D in get_overlapping_areas():
		var candidate: Interactable = area as Interactable
		if candidate == null or not candidate.enabled:
			continue
		var distance: float = global_position.distance_squared_to(candidate.global_position)
		if distance < best_distance:
			best = candidate
			best_distance = distance
	if best == focused:
		return
	if is_instance_valid(focused):
		focused.set_highlighted(false)
	focused = best
	if focused != null:
		focused.set_highlighted(true)
	focus_changed.emit(focused)
