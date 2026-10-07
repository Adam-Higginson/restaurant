class_name ItemDraw
extends RefCounted
## Draws items as placeholder shapes, so counters and the carried stack (and
## later pans on the stove) show them the same way: a square in the item's
## colour, quality pips on food, and a vessel's food inside it with a rim of
## the vessel showing around it. Leaves the outer pixel free for an outline.

## Dark, so pips show on light food like bread as well as on tomatoes.
const PIP_COLOR: Color = Color(0.15, 0.12, 0.12, 1)
## Food squares need room for three pips with a pixel between each.
const MIN_PIP_WIDTH: int = 2 * ItemInstance.MAX_QUALITY - 1
## Food on a vessel stays small, so the vessel shows around it.
const MAX_FOOD_SIZE: int = 6
const PROGRESS_BACK_COLOR: Color = Color(0.15, 0.12, 0.12, 1)
const PROGRESS_COLOR: Color = Color(0.45, 0.85, 0.4, 1)
const PROGRESS_HEIGHT: int = 2


## Draws [param instance] filling [param rect] on [param canvas]. Call it from
## the canvas's [code]_draw()[/code]. [param rect] should be in whole pixels.
static func draw_item(canvas: CanvasItem, instance: ItemInstance, rect: Rect2) -> void:
	canvas.draw_rect(rect, instance.item.color)
	if instance.is_vessel():
		_draw_contents(canvas, instance.contents.get_contents(), rect.grow(-2.0))
	else:
		draw_pips(canvas, instance.quality, rect)


## Draws one pip per quality star just above the bottom edge of [param rect], if
## it's wide enough.
static func draw_pips(canvas: CanvasItem, quality: int, rect: Rect2) -> void:
	if rect.size.x < MIN_PIP_WIDTH:
		return
	var width: int = 2 * quality - 1
	var left: float = rect.position.x + floorf((rect.size.x - width) / 2.0)
	var y: float = rect.end.y - 2.0
	for i: int in quality:
		canvas.draw_rect(Rect2(left + 2 * i, y, 1, 1), PIP_COLOR)


## Draws a bar across the top of [param rect] for the vessel's first running
## reaction, so a lettuce on the board shows it can be chopped. Draws nothing
## when nothing is running.
static func draw_progress(canvas: CanvasItem, contents: VesselContents, rect: Rect2) -> void:
	var active: Array[ActiveReaction] = contents.get_active_reactions()
	if active.is_empty():
		return
	var bar: Rect2 = Rect2(rect.position, Vector2(rect.size.x, PROGRESS_HEIGHT))
	canvas.draw_rect(bar, PROGRESS_BACK_COLOR)
	var filled: float = floorf(rect.size.x * active[0].get_fraction())
	if filled > 0.0:
		canvas.draw_rect(Rect2(bar.position, Vector2(filled, PROGRESS_HEIGHT)), PROGRESS_COLOR)


# One food item fills the middle; two sit side by side; three make a triangle.
static func _draw_contents(canvas: CanvasItem, food: Array[ItemInstance], inner: Rect2) -> void:
	if food.is_empty():
		return
	var space: int = int(minf(inner.size.x, inner.size.y))
	var size: int = mini(space, MAX_FOOD_SIZE) if food.size() == 1 else (space - 1) / 2
	if size <= 0:
		return
	var centre: Vector2 = inner.get_center()
	var offsets: Array[Vector2] = []
	match food.size():
		1:
			offsets = [Vector2(0, 0)]
		2:
			offsets = [Vector2(-0.5, 0), Vector2(0.5, 0)]
		_:
			offsets = [Vector2(-0.5, -0.5), Vector2(0.5, -0.5), Vector2(0, 0.5)]
	for i: int in mini(food.size(), offsets.size()):
		var step: Vector2 = offsets[i] * (size + 1)
		var top_left: Vector2 = (centre + step - Vector2(size, size) / 2.0).floor()
		draw_item(canvas, food[i], Rect2(top_left, Vector2(size, size)))
