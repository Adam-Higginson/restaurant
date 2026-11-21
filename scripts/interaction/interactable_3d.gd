class_name Interactable3D
extends Area3D
## Makes its parent usable in 3D: the player presses "interact" (E or Space)
## or "use_tool" (F) while facing it.
##
## Add as a child of a prop, with a [CollisionShape3D] child of its own
## covering the prop. The prop's script listens to the signals below and
## decides what happens. The player's [InteractionDetector3D] finds it.

## Emitted when the player acts on this while it is enabled. The one button
## does everything: if what they're holding goes here, it goes in; otherwise
## they use the object. See Controls in docs/GDD.md.
signal interacted(player: Player3D)
## Emitted when the player uses a belt tool on this while it is enabled.
signal tool_used(player: Player3D, tool: HandTool)

## Physics layer 2. Only the detector looks on it, so bodies and camera zones
## (layer 1) never see interactables, and the detector never sees them.
const LAYER: int = 1 << 1

## Disabled interactables can't be focused or used (e.g. a busy stove).
@export var enabled: bool = true
## Where the focus arrow floats, above this node's origin, in metres: high
## enough to show over the player's head and stack when seen from behind.
@export var focus_height: float = 2.2


func _ready() -> void:
	collision_layer = LAYER
	collision_mask = 0
	monitoring = false
	monitorable = true


## Uses this interactable on behalf of [param player]. Does nothing while
## disabled.
func interact(player: Player3D) -> void:
	if enabled:
		interacted.emit(player)


## Uses [param tool] on this on behalf of [param player]. Does nothing while
## disabled.
func use_tool(player: Player3D, tool: HandTool) -> void:
	if enabled:
		tool_used.emit(player, tool)
