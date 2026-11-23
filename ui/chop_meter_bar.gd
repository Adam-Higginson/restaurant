class_name ChopMeterBar
extends Control
## The chop meter, drawn over the chopping board you're facing (#152): a
## small brass-rimmed bar with the sweet spot in its middle (bright gold for
## a perfect cut, a paler band either side for a good one) and a marker
## sweeping across it. Cut while the marker's in the gold. With food to cut
## and no knife, it says you need one instead.
##
## Display only: the meter itself is the board's [ChopMeter], ticked by its
## [Counter3D]. This finds the board whose meter is up and draws it there.

const BACKGROUND: Color = Color(0.04, 0.1, 0.13, 0.88)
const BRASS: Color = Color(0.8, 0.6, 0.26)
const GOOD: Color = Color(0.62, 0.45, 0.2)
const PERFECT: Color = Color(1.0, 0.8, 0.36)
const MARKER: Color = Color(1.0, 0.97, 0.9)
const SHADOW: Color = Color(0.0, 0.0, 0.0, 0.5)
const TEXT: Color = Color(0.95, 0.9, 0.8)
const PIP_EMPTY: Color = Color(0.1, 0.2, 0.23, 0.9)
## The bar's size, in the HUD's pixels.
const BAR: Vector2 = Vector2(64, 6)

## The board being drawn, or null.
var counter: Counter3D:
	get:
		return _counter

var _counter: Counter3D = null
var _needs_knife: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = BAR + Vector2(4, 12)


func _process(_delta: float) -> void:
	_counter = null
	_needs_knife = false
	for node: Node in get_tree().get_nodes_in_group(Counter3D.GROUP):
		var board: Counter3D = node as Counter3D
		if board != null and (board.is_meter_up() or board.needs_knife()):
			_counter = board
			_needs_knife = not board.is_meter_up()
			break
	var camera: Camera3D = get_viewport().get_camera_3d()
	visible = _counter != null and camera != null \
			and not camera.is_position_behind(_counter.meter_anchor())
	if visible:
		position = (camera.unproject_position(_counter.meter_anchor()) - size / 2.0).round()
	queue_redraw()


func _draw() -> void:
	if _counter == null:
		return
	if _needs_knife:
		_draw_words("You need a knife")
		return
	var meter: ChopMeter = _counter.meter
	var bar: Rect2 = Rect2(Vector2(2, 6), BAR)
	draw_rect(bar.grow(1), BRASS)
	draw_rect(bar, BACKGROUND)
	_draw_zone(bar, meter.good_width, GOOD)
	_draw_zone(bar, meter.perfect_width, PERFECT)
	var x: float = roundf(bar.position.x + meter.position * bar.size.x)
	draw_rect(Rect2(x, bar.position.y - 2, 2, bar.size.y + 4), SHADOW)
	draw_rect(Rect2(x - 1, bar.position.y - 3, 2, bar.size.y + 4), MARKER)
	_draw_pips(bar, _counter.cut_progress())


# One pip under the bar for each cut the cut under way takes, filled for
# each made.
func _draw_pips(bar: Rect2, progress: Vector2i) -> void:
	if progress.y <= 0:
		return
	var step: float = 5.0
	var left: float = roundf(bar.get_center().x - (progress.y * step - 2.0) / 2.0)
	for pip: int in progress.y:
		var at: Rect2 = Rect2(left + pip * step, bar.end.y + 3, 3, 3)
		draw_rect(at.grow(0.5), BRASS)
		draw_rect(at, PERFECT if pip < progress.x else PIP_EMPTY)


# A band of [param width] (a share of the bar) round the meter's centre.
func _draw_zone(bar: Rect2, width: float, colour: Color) -> void:
	var centre: float = bar.position.x + _counter.meter.centre * bar.size.x
	var half: float = width * bar.size.x / 2.0
	draw_rect(Rect2(roundf(centre - half), bar.position.y, roundf(half * 2.0), bar.size.y), colour)


func _draw_words(words: String) -> void:
	var font: Font = get_theme_default_font()
	var font_size: int = 8
	var width: float = font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var at: Vector2 = Vector2(roundf(size.x / 2.0 - width / 2.0), 10)
	draw_string(font, at + Vector2(1, 1), words, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, SHADOW)
	draw_string(font, at, words, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, TEXT)
