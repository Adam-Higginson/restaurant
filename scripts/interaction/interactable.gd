class_name Interactable
extends Area2D
## Makes its parent usable: the player presses "interact", "pick_up" or
## "use_tool" while facing it.
##
## Add as a child of a prop with a CollisionShape2D child of its own. The prop's
## script listens to the signals below and decides what happens.

## Emitted when the player uses this while it is enabled.
signal interacted(player: Player)
## Emitted when the player presses pick up / put down at this while it is enabled.
signal pick_up_pressed(player: Player)
## Emitted when the player uses a belt tool on this while it is enabled.
signal tool_used(player: Player, tool: HandTool)

## Physics layer 2, named "interaction" in project settings.
const LAYER: int = 1 << 1
const HIGHLIGHT_COLOR: Color = Color(1, 1, 1, 1)
## The highlight sits 1px outside the prop, so it's drawn above neighbouring
## props and the player's body, or they'd cover parts of it. The player's
## carried stack is drawn above it, as it's held in front.
const HIGHLIGHT_Z_INDEX: int = 1

## Disabled interactables can't be focused or used (e.g. a busy stove).
@export var enabled: bool = true

var _highlighted: bool = false


func _ready() -> void:
	collision_layer = LAYER
	collision_mask = 0
	monitoring = false
	monitorable = true
	z_index = HIGHLIGHT_Z_INDEX


func _draw() -> void:
	if not _highlighted:
		return
	for child: Node in get_children():
		var shape_node: CollisionShape2D = child as CollisionShape2D
		if shape_node == null or not shape_node.shape is RectangleShape2D:
			continue
		var size: Vector2 = (shape_node.shape as RectangleShape2D).size
		var rect: Rect2 = Rect2(shape_node.position - size / 2.0, size).grow(1.0)
		PixelDraw.outline(self, rect, HIGHLIGHT_COLOR)


## Uses this interactable on behalf of the player. Does nothing while disabled.
func interact(player: Player) -> void:
	if enabled:
		interacted.emit(player)


## Pick up / put down at this on behalf of the player. Does nothing while disabled.
func pick_up(player: Player) -> void:
	if enabled:
		pick_up_pressed.emit(player)


## Uses [param tool] on this on behalf of the player. Does nothing while disabled.
func use_tool(player: Player, tool: HandTool) -> void:
	if enabled:
		tool_used.emit(player, tool)


func set_highlighted(value: bool) -> void:
	if _highlighted == value:
		return
	_highlighted = value
	queue_redraw()


func is_highlighted() -> bool:
	return _highlighted
