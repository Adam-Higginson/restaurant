class_name CookBubble
extends SpeechBubble
## The face of the bubble over a pan on the hob (#152): the speech bubbles'
## dark pill and tail, with a little clock ring round a flame at its left
## end. The ring fills amber as the food cooks. At the food's golden moment
## it's full and gold, pulsing, beside "Now!"; when the food's done it names
## it and its stars. A [SpeechBubble3D] shows it over the pan ([PanFeel]).
##
## Display only.

const GOLD: Color = Color(1.0, 0.82, 0.36)
const RING_BACK: Color = Color(0.18, 0.16, 0.14, 0.9)
const FLAME: Color = Color(1.0, 0.62, 0.22)
## The ring's radius and thickness, and the gap between it and the words.
const RING: float = 5.5
const RING_WIDTH: float = 2.0
const GAP: float = 4.0

## How far the food has cooked, 0 to 1: how much of the ring is filled.
var fraction: float = 0.0
## How far through its pulse the golden moment is, 0 to 1, or -1 when it's
## not the golden moment.
var golden: float = -1.0

var _colour: Color = WORDS


## Shows the ring [param cooked] of the way round, with [param said] beside
## it in [param colour] (none if empty), and sizes itself to fit.
## [param pulse] is the golden moment's pulse, 0 to 1, or -1 outside it.
func show_cooking(cooked: float, said: String = "", colour: Color = WORDS,
		pulse: float = -1.0) -> void:
	fraction = clampf(cooked, 0.0, 1.0)
	golden = pulse
	_words = said
	_colour = colour
	var ring: Vector2 = Vector2.ONE * RING * 2.0
	var words: Vector2 = text_size(said) if not said.is_empty() else Vector2.ZERO
	var inside: Vector2 = Vector2(ring.x + (GAP + words.x if not said.is_empty() else 0.0),
			maxf(ring.y, words.y))
	size = (inside + PADDING * 2.0 + Vector2(0, TAIL)).ceil()
	queue_redraw()


func _draw() -> void:
	var tall: float = size.y - TAIL
	var panel: StyleBoxFlat = StyleBoxFlat.new()
	panel.bg_color = PANEL
	panel.set_corner_radius_all(mini(int(tall / 2.0), 12))
	panel.corner_detail = 12
	panel.anti_aliasing = true
	panel.anti_aliasing_size = 0.4
	draw_style_box(panel, Rect2(0, 0, size.x, tall))
	draw_colored_polygon(PackedVector2Array([Vector2(TAIL_X + 2.0, tall),
			Vector2(TAIL_X + 8.0, tall), Vector2(TAIL_X, tall + TAIL - 1.0)]), PANEL)
	var centre: Vector2 = Vector2(PADDING.x + RING, tall / 2.0)
	var is_golden: bool = golden >= 0.0
	# The ring: a dark track, filled clockwise from the top as it cooks.
	draw_arc(centre, RING, 0.0, TAU, 32, RING_BACK, RING_WIDTH, true)
	var filled: float = 1.0 if is_golden else fraction
	if filled > 0.0:
		var colour: Color = GOLD if is_golden else SpeechBubble.AMBER
		if is_golden:
			# Pulsing: brightest at the top of the beat.
			colour = colour.lerp(Color.WHITE, 0.45 * golden)
		draw_arc(centre, RING, -PI / 2.0, -PI / 2.0 + TAU * filled, 32, colour,
				RING_WIDTH + (0.6 * golden if is_golden else 0.0), true)
	_draw_flame(centre, is_golden)
	if not _words.is_empty():
		var font: Font = words_font()
		var at: Vector2 = Vector2(PADDING.x + RING * 2.0 + GAP,
				tall / 2.0 + font.get_ascent(FONT_SIZE) / 2.0 - 1.0)
		draw_string(font, at + Vector2(0.4, 0.5), _words, HORIZONTAL_ALIGNMENT_LEFT, -1,
				FONT_SIZE, SHADOW)
		draw_string(font, at, _words, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, _colour)


# A little flame in the middle of the ring: gold at the golden moment.
func _draw_flame(centre: Vector2, is_golden: bool) -> void:
	var colour: Color = GOLD if is_golden else FLAME
	var flame: PackedVector2Array = PackedVector2Array([centre + Vector2(0, -3.2),
			centre + Vector2(1.9, 0.4), centre + Vector2(1.2, 2.2), centre + Vector2(-1.2, 2.2),
			centre + Vector2(-1.9, 0.4)])
	draw_colored_polygon(flame, colour)
	draw_circle(centre + Vector2(0, 1.0), 0.9, Color(1.0, 0.95, 0.75), true, -1.0, true)
