class_name Counter3D
extends StaticBody3D
## A galley counter in 3D. Holds one item, food or a utensil, and swaps it with
## the player's arms on Interact. With a chopping board on it, Use tool (the
## knife) cuts the food on the board.
##
## The rules live in [CounterSlot]; this node connects it to the player and
## shows what's on it, at its [code]ItemSpot[/code] marker.
##
## The chop meter (#152): while you face a board with something on it to cut
## and you've a knife, its [member meter] sweeps, and the HUD draws it over
## the board ([ChopMeterBar]). Each cut is graded by where the marker is
## (see [ChopMeter]), and the grade sets how well the food is cut. From the
## first cut the camera leans in over your shoulder ([code]ChopShot[/code]),
## until you step away or there's nothing left to cut. With food to cut but
## no knife, the HUD says you need one.

## Emitted after each cut on the board, with how well it was made (a
## [enum ChopMeter.Grade]).
signal chopped(grade: int)

## The group every counter is in, so the HUD can find the one being chopped at.
const GROUP: StringName = &"counters"
const CUT: Element = preload("res://data/elements/cut.tres")

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

var _slot: CounterSlot = null
var _meter_up: bool = false
var _needs_knife: bool = false
## The player whose camera is leaning in over this board, or null.
var _leaning: Player3D = null

@onready var _interactable: Interactable3D = $Interactable
@onready var _item_spot: Node3D = $ItemSpot
@onready var _chop_shot: Marker3D = get_node_or_null("ChopShot") as Marker3D


func _ready() -> void:
	add_to_group(GROUP)
	_slot = CounterSlot.new(start_item)
	_slot.changed.connect(_show_item)
	# Making something for the first time can bring back a memory of home.
	_slot.food_made.connect(func(result: ItemInstance) -> void: Game.memories.notice(result.item))
	_interactable.interacted.connect(_on_interacted)
	_interactable.tool_used.connect(_on_tool_used)
	_interactable.describe_interact = func(player: Player3D) -> String:
		return _slot.interact_prompt(player.arms)
	_interactable.describe_tool = func(_player: Player3D, tool: HandTool) -> String:
		return tool.verb if _slot.can_use_tool(tool) else ""
	_show_item()


func _process(delta: float) -> void:
	var player: Player3D = _chopper()
	var knife: HandTool = cutting_tool(player) if player != null else null
	var up: bool = knife != null
	if up and not _meter_up:
		meter.fit_to(knife)
		meter.reset()
	_meter_up = up
	_needs_knife = player != null and not up and has_food_to_cut()
	if up:
		meter.tick(delta)
	elif _leaning != null:
		_lean_out()


## Whether the chop meter is showing: you're facing this board with
## something on it to cut, and a knife.
func is_meter_up() -> bool:
	return _meter_up


## Whether you're facing this board with something to cut, but no knife.
func needs_knife() -> bool:
	return _needs_knife


## Whether there's food on a board here that a knife could cut.
func has_food_to_cut() -> bool:
	var item: ItemInstance = _slot.get_item()
	return item != null and item.is_vessel() and item.contents.would_react_to(CUT)


## The tool [param player] would cut with here: the selected one if it cuts,
## otherwise the first on their toolbar that does. Null if none would.
func cutting_tool(player: Player3D) -> HandTool:
	var selected: HandTool = player.toolbar.selected_tool()
	if selected != null and _slot.can_use_tool(selected):
		return selected
	for tool: HandTool in player.toolbar.get_tools():
		if _slot.can_use_tool(tool):
			return tool
	return null


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


## Where the HUD draws the meter: a little above the board.
func meter_anchor() -> Vector3:
	return _item_spot.global_position + Vector3.UP * 0.45


## Cuts with [param tool], graded by the meter if it's up. Returns whether
## anything was cut.
func cut_with(player: Player3D, tool: HandTool) -> bool:
	var grade: int = meter.grade() if _meter_up else 0
	if not _slot.use_tool(tool, grade):
		return false
	chopped.emit(grade if grade > 0 else ChopMeter.Grade.GOOD)
	if lean_in and _chop_shot != null and player != null and _leaning == null:
		_leaning = player
		player.camera_rig.hold_shot(_chop_shot)
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


func _lean_out() -> void:
	if is_instance_valid(_leaning):
		_leaning.camera_rig.release_shot()
	_leaning = null


func _on_interacted(player: Player3D) -> void:
	_slot.exchange_with(player.arms)


func _on_tool_used(player: Player3D, tool: HandTool) -> void:
	cut_with(player, tool)
