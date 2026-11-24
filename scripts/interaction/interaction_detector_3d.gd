class_name InteractionDetector3D
extends Area3D
## Sits in front of the player, focuses the nearest enabled [Interactable3D]
## it overlaps, and sends it "interact" and "use_tool" presses. A small arrow
## floats over whatever is focused, so you can see what Interact would use.

## Emitted when the focused interactable changes (null when nothing is in reach).
signal focus_changed(interactable: Interactable3D)
## Emitted when Use tool is pressed with nothing here for a tool to work on.
## The [Duellist] swings the knife then.
signal tool_missed
## Emitted when Interact is pressed with nothing here to use. The [Dodge]
## jumps out of the way then.
signal interact_missed

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
## Whether something has the player busy, and the prompts it shows meanwhile.
## See [method set_busy].
var _busy: bool = false
var _busy_interact: String = ""
var _busy_use: String = ""

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
	# Not while asleep, in a cutscene or mid-conversation.
	if not _player.controls_enabled or not accepts_event(event, Input.mouse_mode):
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		if not try_interact():
			interact_missed.emit()
	elif event.is_action_pressed("use_tool"):
		get_viewport().set_input_as_handled()
		if not try_use() and _player.toolbar.selected_tool() != null:
			tool_missed.emit()


## Interacts with the focused interactable, if any. Returns whether something
## was there.
func try_interact() -> bool:
	if not is_instance_valid(focused):
		return false
	focused.interact(_player)
	return true


## Uses what's in the selected slot (#207): a tool on the focused
## interactable (the knife on a board), or a held item (put the tomato down,
## fill the pot). Nothing else on the toolbar is ever used. Returns whether
## something was done. The recipe book is read instead, wherever you are and
## whatever's in reach (#184).
func try_use() -> bool:
	if _is_reading_book():
		return RecipeBook.open_book(self, _player) > 0
	if not is_instance_valid(focused):
		return false
	# A tool in hand goes to what's in front, even if it does nothing there:
	# the knife never swings at the galley's furniture.
	var tool: HandTool = _player.toolbar.selected_tool()
	if tool != null:
		focused.use_tool(_player, tool)
		return true
	if _player.toolbar.top() != null and not focused.use_prompt(_player).is_empty():
		focused.use(_player)
		return true
	return false


## The tool Use would use right now: the selected one, if it does anything
## on the focused interactable; otherwise null. Never the recipe book: that's
## read, not used on anything.
func tool_to_use() -> HandTool:
	if not is_instance_valid(focused):
		return null
	var selected: HandTool = _player.toolbar.selected_tool()
	if selected == null or selected.is_recipe_book:
		return null
	if focused.tool_prompt(_player, selected).is_empty():
		return null
	return selected


## Shows [param interact_text] and [param use_text] as the button prompts in
## place of the focused interactable's, while something has the player busy
## (chopping: "Stop chopping", "Cut"). [method clear_busy] ends it.
func set_busy(interact_text: String, use_text: String) -> void:
	_busy = true
	_busy_interact = interact_text
	_busy_use = use_text


## Goes back to prompting for the focused interactable.
func clear_busy() -> void:
	_busy = false


## Whether this should act on [param event], given the current
## [param mouse_mode]. Mouse clicks only count while the mouse is captured:
## with the cursor free, a click just captures it again (the camera rig does
## that), so it mustn't also chop or put down.
static func accepts_event(event: InputEvent, mouse_mode: Input.MouseMode) -> bool:
	if event is InputEventMouseButton:
		return mouse_mode == Input.MOUSE_MODE_CAPTURED
	return true


## What Interact would do right now, e.g. "Pick up Tomato", or "" with
## nothing in reach or nothing to do. The HUD prompt shows it.
func interact_prompt() -> String:
	if _busy:
		return _busy_interact
	if not is_instance_valid(focused):
		return ""
	return focused.interact_prompt(_player)


## What Use would do right now with the selected slot, e.g. "Chop" or "Put
## down Tomato", or "" with nothing in reach or nothing it does here.
func tool_prompt() -> String:
	if _busy:
		return _busy_use
	if _is_reading_book():
		return _player.toolbar.selected_tool().verb
	var tool: HandTool = tool_to_use()
	if tool != null:
		return focused.tool_prompt(_player, tool)
	if not is_instance_valid(focused) or _player.toolbar.top() == null:
		return ""
	return focused.use_prompt(_player)


# Whether the recipe book is the selected slot: Use reads it.
func _is_reading_book() -> bool:
	var selected: HandTool = _player.toolbar.selected_tool()
	return selected != null and selected.is_recipe_book


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
	if not is_instance_valid(focused) or not _player.controls_enabled:
		_arrow.hide()
		return
	_arrow.show()
	# Where the interactable is drawn this frame, so the arrow rides the
	# sailing ship smoothly.
	var above: Vector3 = focused.get_global_transform_interpolated().origin \
			+ Vector3.UP * focused.focus_height
	var bob: float = sin(_bob_time * arrow_bob_rate * TAU) * arrow_bob_height
	_arrow.global_position = above + Vector3.UP * bob
