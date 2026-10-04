class_name Interactable
extends Area2D
## Makes its parent usable: the player presses "interact" while facing it.
##
## Add as a child of a prop with a CollisionShape2D child of its own. The prop's
## script listens to [signal interacted] and decides what happens.

## Emitted when the player uses this while it is enabled.
signal interacted(player: Player)

## Physics layer 2, named "interaction" in project settings.
const LAYER: int = 1 << 1
const HIGHLIGHT_COLOR: Color = Color(1, 1, 1, 1)

## Disabled interactables can't be focused or used (e.g. a busy stove).
@export var enabled: bool = true

var _highlighted: bool = false


func _ready() -> void:
	collision_layer = LAYER
	collision_mask = 0
	monitoring = false
	monitorable = true


func _draw() -> void:
	if not _highlighted:
		return
	for child: Node in get_children():
		var shape_node: CollisionShape2D = child as CollisionShape2D
		if shape_node == null or not shape_node.shape is RectangleShape2D:
			continue
		var size: Vector2 = (shape_node.shape as RectangleShape2D).size
		var rect: Rect2 = Rect2(shape_node.position - size / 2.0, size).grow(1.0)
		_draw_outline(rect)


## Uses this interactable on behalf of the player. Does nothing while disabled.
func interact(player: Player) -> void:
	if enabled:
		interacted.emit(player)


func set_highlighted(value: bool) -> void:
	if _highlighted == value:
		return
	_highlighted = value
	queue_redraw()


func is_highlighted() -> bool:
	return _highlighted


## Draws a crisp 1px outline just inside the rect, using filled rects so it
## stays pixel-aligned.
func _draw_outline(rect: Rect2) -> void:
	var p: Vector2 = rect.position
	var s: Vector2 = rect.size
	draw_rect(Rect2(p, Vector2(s.x, 1)), HIGHLIGHT_COLOR)
	draw_rect(Rect2(p + Vector2(0, s.y - 1), Vector2(s.x, 1)), HIGHLIGHT_COLOR)
	draw_rect(Rect2(p, Vector2(1, s.y)), HIGHLIGHT_COLOR)
	draw_rect(Rect2(p + Vector2(s.x - 1, 0), Vector2(1, s.y)), HIGHLIGHT_COLOR)
