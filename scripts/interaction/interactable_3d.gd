class_name Interactable3D
extends Area3D
## Makes its parent usable in 3D. Facing it, the player has two buttons (#207):
## - **Interact** (right click, E): works the thing itself. Pick it up, talk,
##   open it, ring it.
## - **Use** (left click, F): uses what's in the player's selected slot on it.
##   Put the held food down, chop with the knife, fill the pot.
##
## Add as a child of a prop, with a [CollisionShape3D] child of its own
## covering the prop. The prop's script listens to the signals below and
## decides what happens. The player's [InteractionDetector3D] finds it.

## Emitted when the player interacts with this while it is enabled. See
## Controls in docs/GDD.md.
signal interacted(player: Player3D)
## Emitted when the player uses the item in their selected slot on this while
## it is enabled.
signal used(player: Player3D)
## Emitted when the player uses the tool in their selected slot on this while
## it is enabled.
signal tool_used(player: Player3D, tool: HandTool)

## Physics layer 2. Only the detector looks on it, so bodies and camera zones
## (layer 1) never see interactables, and the detector never sees them.
const LAYER: int = 1 << 1

## Disabled interactables can't be focused or used (e.g. a busy stove).
@export var enabled: bool = true
## Where the focus arrow floats, above this node's origin, in metres: high
## enough to show over the player's head and stack when seen from behind.
@export var focus_height: float = 2.2

## Says what [method interact] would do for a player, for the HUD prompt: a
## function taking a [Player3D] and returning text like "Pick up Tomato", or
## "" for nothing. Set by the prop; unset means no prompt.
var describe_interact: Callable = Callable()
## Says what [method use] would do with the held item: a function taking a
## [Player3D] and returning text like "Put down Tomato", or "" for nothing.
var describe_use: Callable = Callable()
## Says what [method use_tool] would do: a function taking a [Player3D] and a
## [HandTool] and returning text like "Chop", or "" for nothing.
var describe_tool: Callable = Callable()


func _ready() -> void:
	collision_layer = LAYER
	collision_mask = 0
	monitoring = false
	monitorable = true


## Interacts with this on behalf of [param player]. Does nothing while
## disabled.
func interact(player: Player3D) -> void:
	if enabled:
		interacted.emit(player)


## What [method interact] would do for [param player], e.g. "Open Pantry",
## or "" for nothing (or while disabled).
func interact_prompt(player: Player3D) -> String:
	if not enabled or not describe_interact.is_valid():
		return ""
	var text: String = describe_interact.call(player)
	return text


## Uses [param player]'s held item on this. Does nothing while disabled.
func use(player: Player3D) -> void:
	if enabled:
		used.emit(player)


## What [method use] would do for [param player], e.g. "Put down Tomato", or
## "" for nothing (or while disabled).
func use_prompt(player: Player3D) -> String:
	if not enabled or not describe_use.is_valid():
		return ""
	var text: String = describe_use.call(player)
	return text


## What [method use_tool] would do with [param tool], e.g. "Chop", or "" for
## nothing (or while disabled).
func tool_prompt(player: Player3D, tool: HandTool) -> String:
	if not enabled or not describe_tool.is_valid():
		return ""
	var text: String = describe_tool.call(player, tool)
	return text


## Uses [param tool] on this on behalf of [param player]. Does nothing while
## disabled.
func use_tool(player: Player3D, tool: HandTool) -> void:
	if enabled:
		tool_used.emit(player, tool)
