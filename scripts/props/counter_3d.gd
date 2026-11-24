class_name Counter3D
extends StaticBody3D
## A galley counter in 3D. Holds one item, food or a utensil. Use (left click)
## puts the held item down here, or into the board or plate here; Interact
## (right click) picks up what's here. With a chopping board on it and the
## knife in hand, Use starts chopping.
##
## The rules live in [CounterSlot]; this node connects it to the player and
## shows what's on it, at its [code]ItemSpot[/code] marker.
##
## Chop mode (#152, #207): knife selected, facing a board with food to cut,
## Use starts it. The player stands rooted at the board, the camera leans in
## over their shoulder ([code]ChopShot[/code]), and the [member meter] sweeps
## while the HUD draws it ([ChopMeterBar]). Each Use is a cut, graded by where
## the marker is (see [ChopMeter]); the grade sets how well the food is cut.
## Interact or Esc stops, and it stops by itself after the last cut. Facing
## food to cut without the knife in hand, the HUD says so.

## Emitted after each cut on the board, with how well it was made (a
## [enum ChopMeter.Grade]).
signal chopped(grade: int)

## The group every counter is in, so the HUD can find the one being chopped at.
const GROUP: StringName = &"counters"
const CUT: Element = preload("res://data/elements/cut.tres")
## How long a cut lights the meter up for, in seconds.
const FLASH_SECONDS: float = 0.3
## How fast you step up to the board, in metres a second.
const STEP_SPEED: float = 4.0
## How long chop mode lingers after the last cut, so it's seen to land.
const FINISH_SECONDS: float = 0.5

## Something already on the counter when the scene starts (the galley's
## chopping board).
@export var start_item: Item = null
## Lean the camera in over the board while chopping.
@export var lean_in: bool = true

## What's on the counter. Created when the counter is ready, never replaced.
var slot: CounterSlot:
	get:
		return _slot

## The chop meter. Created once, never replaced.
var meter: ChopMeter = ChopMeter.new()
## How the last cut went (a [enum ChopMeter.Grade]), and how much longer it
## lights the meter up, in seconds.
var last_grade: int = 0
var flash_left: float = 0.0

var _slot: CounterSlot = null
var _needs_knife: bool = false
## Whoever is chopping here (chop mode, #207), or null; and their knife.
var _chopping: Player3D = null
var _tool: HandTool = null
## Seconds until chop mode ends after the last cut, or below zero.
var _finish_left: float = -1.0
## The player whose camera is leaning in over this board, or null.
var _leaning: Player3D = null
## Whoever cut here last, or null.
var _last_chopper: Player3D = null
## Whoever is stepping up to the board, or null.
var _stepping: Player3D = null

@onready var _interactable: Interactable3D = $Interactable
@onready var _item_spot: Node3D = $ItemSpot
@onready var _chop_shot: Marker3D = get_node_or_null("ChopShot") as Marker3D


func _ready() -> void:
	add_to_group(GROUP)
	_slot = CounterSlot.new(start_item)
	_slot.changed.connect(_show_item)
	_interactable.interacted.connect(_on_interacted)
	_interactable.used.connect(_on_used)
	_interactable.tool_used.connect(_on_tool_used)
	_interactable.describe_interact = func(player: Player3D) -> String:
		return _slot.take_prompt(player.arms)
	_interactable.describe_use = func(player: Player3D) -> String:
		return _slot.use_prompt(player.arms)
	_interactable.describe_tool = func(_player: Player3D, tool: HandTool) -> String:
		return tool.verb if _chopping == null and _can_cut_with(tool) else ""
	_show_item()


func _process(delta: float) -> void:
	flash_left = maxf(flash_left - delta, 0.0)
	if _chopping != null:
		_keep_chopping(delta)
	var facing: Player3D = _chopper()
	_needs_knife = _chopping == null and facing != null and has_food_to_cut() \
			and not _can_cut_with(facing.toolbar.selected_tool())
	_step(_chopping, delta)


# Chop mode owns the buttons while it's on, ahead of everything else (the
# camera rig frees the mouse on Esc otherwise): Use cuts; Interact or Esc
# stops chopping.
func _input(event: InputEvent) -> void:
	if _chopping == null:
		return
	if not InteractionDetector3D.accepts_event(event, Input.mouse_mode):
		return
	if event.is_action_pressed("use_tool"):
		get_viewport().set_input_as_handled()
		cut_with(_chopping, _tool)
	elif event.is_action_pressed("interact") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		stop_chopping()


## Whether the chop meter is showing: someone is chopping here.
func is_meter_up() -> bool:
	return _chopping != null


## Whether someone is chopping here.
func is_chopping() -> bool:
	return _chopping != null


## Whether you're facing this board with something to cut, but no knife in
## your hand (#207: the knife must be the selected slot).
func needs_knife() -> bool:
	return _needs_knife


## What the HUD says when [method needs_knife]: take your knife out if you've
## one on the toolbar, otherwise that you need one.
func knife_hint() -> String:
	var facing: Player3D = _chopper()
	if facing != null:
		for tool: HandTool in facing.toolbar.get_tools():
			if _can_cut_with(tool):
				return "Take out your knife"
	return "You need a knife"


## Whether there's food on a board here that a knife could cut.
func has_food_to_cut() -> bool:
	var item: ItemInstance = _slot.get_item()
	return item != null and item.is_vessel() and item.contents.would_react_to(CUT)


## Starts chop mode (#207): [param player], knife in hand, stands rooted at the
## board, the camera leans in over their shoulder and the meter sweeps. Use
## cuts ([method cut_with]); Interact or Esc stops ([method stop_chopping]),
## and it stops by itself once there's nothing left to cut. Returns whether
## it started: not with nothing to cut, a tool that doesn't cut, or someone
## already chopping.
func start_chopping(player: Player3D, tool: HandTool) -> bool:
	if _chopping != null or player == null or not _can_cut_with(tool):
		return false
	_chopping = player
	_tool = tool
	_finish_left = -1.0
	meter.fit_to(tool)
	meter.reset()
	player.controls_enabled = false
	var detector: InteractionDetector3D = _detector_of(player)
	if detector != null:
		detector.set_busy("Stop chopping", "Cut")
	if lean_in and _chop_shot != null:
		_leaning = player
		player.camera_rig.hold_shot(_chop_shot)
	_step_up(player)
	return true


## Ends chop mode: the player can walk again and the camera leans back out.
func stop_chopping() -> void:
	if _chopping == null:
		return
	var player: Player3D = _chopping
	_chopping = null
	_tool = null
	_stepping = null
	if is_instance_valid(player):
		player.controls_enabled = true
		var detector: InteractionDetector3D = _detector_of(player)
		if detector != null:
			detector.clear_busy()
	_lean_out()


## How far the cut under way has got: x is the cuts made, y the cuts it
## takes (slicing a tomato takes 2). Zero when nothing's being cut.
func cut_progress() -> Vector2i:
	var item: ItemInstance = _slot.get_item()
	if item == null or not item.is_vessel():
		return Vector2i.ZERO
	for active: ActiveReaction in item.contents.get_active_reactions():
		if active.reaction.driving_element() == CUT:
			return Vector2i(roundi(active.progress), roundi(active.reaction.amount))
	return Vector2i.ZERO


## Whoever cut here last, or null.
func last_chopper() -> Player3D:
	return _last_chopper if is_instance_valid(_last_chopper) else null


## Where the HUD draws the meter: a little above the board.
func meter_anchor() -> Vector3:
	return _item_spot.global_position + Vector3.UP * 0.45


## Cuts with [param tool], graded by the meter while chopping (ungraded
## otherwise, as tests and scripted cuts do). Returns whether anything was
## cut. The last cut ends chop mode a moment later.
func cut_with(player: Player3D, tool: HandTool) -> bool:
	var grade: int = meter.grade() if _chopping != null else 0
	if not _slot.use_tool(tool, grade):
		return false
	_last_chopper = player
	last_grade = grade if grade > 0 else ChopMeter.Grade.GOOD
	flash_left = FLASH_SECONDS
	chopped.emit(last_grade)
	if _chopping != null and not has_food_to_cut():
		_finish_left = FINISH_SECONDS
	return true


# Swaps the old model for one of what's here now.
func _show_item() -> void:
	for child: Node in _item_spot.get_children():
		# Out of the tree now, not at the end of the frame, so there's never
		# an old and a new model at once.
		_item_spot.remove_child(child)
		child.queue_free()
	var item: ItemInstance = _slot.get_item()
	if item != null:
		_item_spot.add_child(ItemModel.build(item))


# The player facing this counter, if they are, or null.
func _chopper() -> Player3D:
	if not is_inside_tree():
		return null
	var player: Player3D = get_tree().get_first_node_in_group(Player3D.GROUP) as Player3D
	if player == null or not player.controls_enabled:
		return null
	var detector: InteractionDetector3D = player.get_node_or_null("InteractionDetector") \
			as InteractionDetector3D
	if detector == null or detector.focused != _interactable:
		return null
	return player


# Starts [param player] stepping up to the board (its ChopStand mark), so the
# knife comes down on the food rather than the air in front of it.
func _step_up(player: Player3D) -> void:
	if get_node_or_null("ChopStand") != null:
		_stepping = player
		player.face_towards(_item_spot.global_position)


# Moves whoever is stepping up a little nearer the board, [param facing] the
# player facing it now. Walking, or turning to something else, stops it.
func _step(facing: Player3D, delta: float) -> void:
	if _stepping == null:
		return
	if _stepping != facing or _stepping.is_walking:
		_stepping = null
		return
	var stand: Marker3D = get_node("ChopStand") as Marker3D
	var gap: Vector3 = stand.global_position - _stepping.global_position
	gap.y = 0.0
	if gap.length() < 0.02:
		_stepping = null
		return
	_stepping.global_position += gap.limit_length(STEP_SPEED * delta)


func _lean_out() -> void:
	if is_instance_valid(_leaning):
		_leaning.camera_rig.release_shot()
	_leaning = null


# Whether [param tool] would cut something on the board here.
func _can_cut_with(tool: HandTool) -> bool:
	return tool != null and _slot.can_use_tool(tool)


# While chopping: the meter sweeps, and chop mode ends after the last cut,
# or if the knife is put away (another slot selected) or the chopper is gone.
func _keep_chopping(delta: float) -> void:
	if not is_instance_valid(_chopping) or _chopping.toolbar.selected_tool() != _tool:
		stop_chopping()
		return
	meter.tick(delta)
	if _finish_left >= 0.0:
		_finish_left -= delta
		if _finish_left < 0.0:
			stop_chopping()


func _detector_of(player: Player3D) -> InteractionDetector3D:
	return player.get_node_or_null("InteractionDetector") as InteractionDetector3D


# Interact takes from the counter: the board's top food, or the whole item.
func _on_interacted(player: Player3D) -> void:
	_slot.take_into(player.arms)


# Use puts the held item here.
func _on_used(player: Player3D) -> void:
	_slot.use_with(player.arms)


# Use with the knife starts chopping.
func _on_tool_used(player: Player3D, tool: HandTool) -> void:
	start_chopping(player, tool)
