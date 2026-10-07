class_name PixelDraw
extends RefCounted
## Drawing helpers that stay pixel-aligned for the pixel-art placeholders.


## Draws a crisp 1px outline just inside [param rect] on [param canvas], using
## filled rects. Call it from the canvas's [code]_draw()[/code].
static func outline(canvas: CanvasItem, rect: Rect2, color: Color) -> void:
	var p: Vector2 = rect.position
	var s: Vector2 = rect.size
	canvas.draw_rect(Rect2(p, Vector2(s.x, 1)), color)
	canvas.draw_rect(Rect2(p + Vector2(0, s.y - 1), Vector2(s.x, 1)), color)
	canvas.draw_rect(Rect2(p, Vector2(1, s.y)), color)
	canvas.draw_rect(Rect2(p + Vector2(s.x - 1, 0), Vector2(1, s.y)), color)
