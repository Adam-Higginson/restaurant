class_name SpeechBubble
extends Control
## The face of a speech bubble: a dark, see-through panel with a few pale
## words on it and a tail at its bottom-left corner. A [SpeechBubble3D] shows
## it in the world beside whoever's speaking.
##
## Display only.

## How a bubble is drawn.
enum Style {
	## Said aloud: a panel with a tail.
	SPEECH,
	## Thought, not said: a panel with a trail of little squares.
	THOUGHT,
	## Shouted or startled: amber words.
	EXCLAIM,
	## A noise rather than words (a snore, a hum): a panel with a tail, the
	## words paler and quieter.
	SOUND,
}

const PANEL: Color = Color(0.07, 0.08, 0.1, 0.56)
const SHADOW: Color = Color(0.0, 0.0, 0.0, 0.55)
const WORDS: Color = Color(0.96, 0.93, 0.85)
const THOUGHT_WORDS: Color = Color(0.8, 0.86, 0.88)
## Paler and a little see-through, so a hum reads as a noise, not speech.
const SOUND_WORDS: Color = Color(0.86, 0.82, 0.74, 0.72)
const AMBER: Color = Color(1.0, 0.74, 0.34)

const FONT: Font = preload("res://assets/fonts/dialogue_font.tres")
const FONT_SIZE: int = 10
## The widest a bubble's words run before wrapping, in canvas pixels.
const MAX_TEXT_WIDTH: float = 140.0
## Space between the words and the panel's edge.
const PADDING: Vector2 = Vector2(11, 4)
## How much the words lean, as in a comic's lettering.
const SLANT: float = 0.18
## How tall the tail is, under the panel.
const TAIL: float = 6.0
## How far along the panel the tail's tip is, from its left edge.
const TAIL_X: float = 14.0

## The words showing.
var text: String:
	get:
		return _words

## [constant FONT], leaning by [constant SLANT]. Made the first time it's needed.
static var _slanted: FontVariation = null

var _words: String = ""
var _style: Style = Style.SPEECH


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var wide: float = size.x
	var tall: float = size.y - TAIL
	# A smooth, round-cornered panel.
	var panel: StyleBoxFlat = StyleBoxFlat.new()
	panel.bg_color = PANEL
	# Ends as round as the panel is tall: a full pill for one line.
	panel.set_corner_radius_all(mini(int(tall / 2.0), 12))
	panel.corner_detail = 12
	panel.anti_aliasing = true
	panel.anti_aliasing_size = 0.4
	draw_style_box(panel, Rect2(0, 0, wide, tall))
	if _style == Style.THOUGHT:
		# A trail of dots shrinking towards the thinker.
		draw_circle(Vector2(TAIL_X + 4.0, tall + 2.2), 1.6, PANEL, true, -1.0, true)
		draw_circle(Vector2(TAIL_X + 1.0, tall + 5.0), 0.9, PANEL, true, -1.0, true)
		_draw_words(THOUGHT_WORDS)
		return
	# A small tail leaning towards the speaker.
	draw_colored_polygon(PackedVector2Array([Vector2(TAIL_X + 2.0, tall),
			Vector2(TAIL_X + 8.0, tall), Vector2(TAIL_X, tall + TAIL - 1.0)]), PANEL)
	var color: Color = WORDS
	if _style == Style.EXCLAIM:
		color = AMBER
	elif _style == Style.SOUND:
		color = SOUND_WORDS
	_draw_words(color)


## Shows [param words] in [param style], and sizes itself to fit them.
func show_words(words: String, style: Style = Style.SPEECH) -> void:
	_words = words
	_style = style
	size = text_size(words) + PADDING * 2.0 + Vector2(0, TAIL)
	queue_redraw()


## How much room [param words] take, wrapped at [constant MAX_TEXT_WIDTH]:
## as wide as the longest line, and as tall as all of them.
static func text_size(words: String) -> Vector2:
	var font: Font = words_font()
	var one_line: Vector2 = font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
	if one_line.x <= MAX_TEXT_WIDTH:
		return one_line.ceil()
	var lines: TextParagraph = TextParagraph.new()
	lines.width = MAX_TEXT_WIDTH
	lines.add_string(words, font, FONT_SIZE)
	var widest: float = 0.0
	for line: int in lines.get_line_count():
		widest = maxf(widest, lines.get_line_width(line))
	return Vector2(ceilf(widest), ceilf(lines.get_size().y))


## The font bubbles are lettered in: [constant FONT], leaning a little.
static func words_font() -> Font:
	if _slanted == null:
		_slanted = FontVariation.new()
		_slanted.base_font = FONT
		# A variation of a variation forgets the first one's weight, so carry
		# it across.
		var weighted: FontVariation = FONT as FontVariation
		if weighted != null:
			_slanted.base_font = weighted.base_font
			_slanted.variation_opentype = weighted.variation_opentype
		_slanted.variation_transform = Transform2D(Vector2(1.0, SLANT), Vector2(0.0, 1.0),
				Vector2.ZERO)
	return _slanted


# Writes the words in the middle of the panel, with a soft shadow so they
# read over a see-through panel.
func _draw_words(color: Color) -> void:
	var font: Font = words_font()
	var wide: float = size.x - PADDING.x * 2.0
	var at: Vector2 = PADDING + Vector2(0, font.get_ascent(FONT_SIZE))
	draw_multiline_string(font, at + Vector2(0.4, 0.5), _words, HORIZONTAL_ALIGNMENT_CENTER,
			wide, FONT_SIZE, -1, SHADOW)
	draw_multiline_string(font, at, _words, HORIZONTAL_ALIGNMENT_CENTER, wide, FONT_SIZE, -1,
			color)
