class_name DialogueBox
extends Control
## The box a proper conversation is read in, at the bottom of the screen: a
## dark sea-teal panel in a riveted brass frame, the speaker's name on a
## little plank at its top-left corner, and their words typed out
## letter by letter. When there's a reply to pick, the
## choices are listed in place of the words.
##
## Display only: it shows what it's told to and knows nothing of what comes
## next. The conversation decides that and reads the buttons.

## Emitted when a line has finished typing out.
signal typed
## Emitted as each letter of a line appears.
signal letter_typed(letter: String)

const BACKGROUND: Color = Color(0.04, 0.1, 0.13, 0.88)
const BACKGROUND_EDGE: Color = Color(0.1, 0.2, 0.23, 0.9)
const BRASS_DARK: Color = Color(0.36, 0.24, 0.09)
const BRASS: Color = Color(0.8, 0.6, 0.26)
const BRASS_LIGHT: Color = Color(0.98, 0.85, 0.5)
const PLANK: Color = Color(0.37, 0.24, 0.14)
const PLANK_DARK: Color = Color(0.19, 0.12, 0.07)
const PLANK_LIGHT: Color = Color(0.5, 0.34, 0.2)
const AMBER: Color = Color(1.0, 0.74, 0.34)
const FLAME_CORE: Color = Color(1.0, 0.95, 0.7)
const CHOICE_COLOR: Color = Color(0.78, 0.8, 0.76)
const SELECTED_COLOR: Color = Color(1.0, 0.96, 0.85)

## The rounded font the words are set in (M PLUS Rounded 1c, SIL Open Font Licence).
const FONT: Font = preload("res://assets/fonts/dialogue_font.tres")
const FONT_SIZE: int = 10

## Seconds the typing waits after a comma, and at the end of a sentence.
const COMMA_PAUSE: float = 0.12
const SENTENCE_PAUSE: float = 0.3

## How tall the box is, and how many choices it then has room for.
const HEIGHT: float = 58.0
const CHOICES_THAT_FIT: int = 3
## The most choices shown at once: the box grows upwards to fit this many,
## and a longer list scrolls.
const MOST_CHOICES_SHOWN: int = 4
## How tall one choice is.
const CHOICE_HEIGHT: float = 15.0

## How many letters are typed out a second.
@export var letters_per_second: float = 45.0
## How far the "more" arrow bobs, in canvas pixels, and how often a second.
@export var arrow_bob: float = 1.5
@export var arrow_bob_rate: float = 1.4

## Which choice the cursor is on, from 0.
var selected: int:
	get:
		return _selected

var _typing: bool = false
## How many letters are showing, as a fraction so slow speeds still add up.
var _letters: float = 0.0
## Whether the line showing is the last, so the arrow becomes a square.
var _last: bool = false
## Seconds left of a pause after a letter, before the next appears.
var _pause: float = 0.0
var _selected: int = 0
## Every choice on offer, and the first one in view.
var _options: PackedStringArray = PackedStringArray()
var _first_shown: int = 0
var _time: float = 0.0

@onready var _name: Label = %Name
@onready var _text: RichTextLabel = %Text
@onready var _choices: VBoxContainer = %Choices


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()


func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	if _typing:
		_type(delta)
	# The arrow bobs and the cursor flickers.
	queue_redraw()


func _draw() -> void:
	_draw_frame()
	if _name.visible:
		_draw_name_plank()
	if _choices.visible:
		_draw_cursor()
	elif not _typing:
		_draw_arrow()


## Types out [param text] as said by [param person]. With no person there's
## no name (a narrator). [param is_last] says nothing follows, so the arrow
## shows a square instead.
func show_line(person: Person, text: String, is_last: bool = false) -> void:
	_choices.hide()
	_text.show()
	_name.visible = person != null
	if person != null:
		_name.text = person.display_name
	_set_height(HEIGHT)
	_text.text = to_bbcode(text)
	_text.visible_characters = 0
	_letters = 0.0
	_pause = 0.0
	_last = is_last
	_typing = true
	show()
	queue_redraw()


## Lists [param options] to pick from, the cursor on the first. The box
## grows to fit up to [constant MOST_CHOICES_SHOWN]; a longer list scrolls as
## the cursor moves.
func show_choices(options: PackedStringArray) -> void:
	_options = options
	_first_shown = 0
	_typing = false
	_text.hide()
	_choices.show()
	_set_height(HEIGHT + CHOICE_HEIGHT * maxi(shown_count() - CHOICES_THAT_FIT, 0))
	show()
	select(0)


## Moves the cursor to choice [param index], wrapping round at either end,
## and scrolls the list so it's in view.
func select(index: int) -> void:
	if _options.is_empty():
		return
	_selected = posmod(index, _options.size())
	_first_shown = first_shown_for(_selected, _first_shown, shown_count())
	_fill_choices()
	queue_redraw()


## How many choices are in view at once.
func shown_count() -> int:
	return mini(_options.size(), MOST_CHOICES_SHOWN)


## The first choice in view once the cursor is on [param chosen], for a list
## showing [param count] at a time whose first in view was [param first]: it
## only moves as far as it must to keep the cursor in view.
static func first_shown_for(chosen: int, first: int, count: int) -> int:
	if chosen < first:
		return chosen
	if chosen >= first + count:
		return chosen - count + 1
	return first


## The whole of the line showing, without its markup.
func line_text() -> String:
	return _text.get_parsed_text()


## As much of the line as has typed out so far.
func shown_text() -> String:
	var words: String = _text.get_parsed_text()
	return words if _text.visible_characters < 0 else words.left(_text.visible_characters)


## The name on the plate, or "" for a narrator.
func speaker_name() -> String:
	return _name.text if _name.visible else ""


## The choices in view, top to bottom.
func shown_choices() -> PackedStringArray:
	var texts: PackedStringArray = PackedStringArray()
	for child: Node in _choices.get_children():
		texts.append((child as Label).text)
	return texts


## Whether a line is still typing out.
func is_typing() -> bool:
	return _typing


## Shows the rest of the line at once.
func finish_typing() -> void:
	if not _typing:
		return
	_typing = false
	_text.visible_characters = -1
	queue_redraw()
	typed.emit()


## Puts the box away.
func close() -> void:
	_typing = false
	hide()


## How long the typing waits after [param letter] before going on, in
## seconds: a beat at a comma and a breath at the end of a sentence, so lines
## read like speech rather than a ticker.
static func pause_after(letter: String) -> float:
	match letter:
		".", "!", "?", "…":
			return SENTENCE_PAUSE
		",", ";", ":":
			return COMMA_PAUSE
	return 0.0


## Turns a line as written into the BBCode a [RichTextLabel] draws:
## [code]*sea-fennel*[/code] becomes amber, and square brackets stay as typed.
static func to_bbcode(text: String) -> String:
	var safe: String = text.replace("[", "[lb]")
	var stars: RegEx = RegEx.create_from_string("\\*([^*]+)\\*")
	return stars.sub(safe, "[color=#%s]$1[/color]" % AMBER.to_html(false), true)


# Shows the letters that are due, one at a time, each announced so it can
# sound, and stopping for a moment where pause_after says to.
func _type(delta: float) -> void:
	if _pause > 0.0:
		_pause -= delta
		return
	_letters += letters_per_second * delta
	var total: int = _text.get_total_character_count()
	var words: String = _text.get_parsed_text()
	var showing: int = _text.visible_characters
	while showing < mini(int(_letters), total):
		var letter: String = words[showing] if showing < words.length() else ""
		showing += 1
		letter_typed.emit(letter)
		_pause = pause_after(letter) if showing < total else 0.0
		if _pause > 0.0:
			_letters = float(showing)
			break
	_text.visible_characters = showing
	if showing >= total:
		finish_typing()


# The panel, its brass border and a rivet in each corner.
func _draw_frame() -> void:
	var box: Rect2 = Rect2(Vector2.ZERO, size)
	draw_rect(box.grow(-3.0), BACKGROUND)
	PixelDraw.outline(self, box.grow(-3.0), BACKGROUND_EDGE)
	PixelDraw.outline(self, box, BRASS_DARK)
	PixelDraw.outline(self, box.grow(-1.0), BRASS)
	PixelDraw.outline(self, box.grow(-2.0), BRASS_DARK)
	# A highlight along the top of the brass, as if lit from above.
	draw_rect(Rect2(2, 1, size.x - 4, 1), BRASS_LIGHT)
	for corner: Vector2 in [Vector2.ZERO, Vector2(size.x - 5, 0), Vector2(0, size.y - 5),
			Vector2(size.x - 5, size.y - 5)]:
		draw_rect(Rect2(corner, Vector2(5, 5)), BRASS_DARK)
		draw_rect(Rect2(corner + Vector2(1, 1), Vector2(3, 3)), BRASS)
		draw_rect(Rect2(corner + Vector2(1, 1), Vector2(1, 1)), BRASS_LIGHT)


# The little plank the name is written on, pinned over the frame's top edge.
func _draw_name_plank() -> void:
	var wide: float = _name.get_minimum_size().x + 16.0
	var plank: Rect2 = Rect2(10, -9, wide, 14)
	draw_rect(plank, PLANK)
	PixelDraw.outline(self, plank, PLANK_DARK)
	draw_rect(Rect2(plank.position + Vector2(1, 1), Vector2(wide - 2, 1)), PLANK_LIGHT)
	# A pin at each end.
	draw_rect(Rect2(plank.position + Vector2(3, 6), Vector2(2, 2)), BRASS)
	draw_rect(Rect2(plank.position + Vector2(wide - 5, 6), Vector2(2, 2)), BRASS)


# A bobbing triangle when there's more to read; a still square at the end.
func _draw_arrow() -> void:
	var at: Vector2 = Vector2(size.x - 16, size.y - 12)
	if _last:
		draw_rect(Rect2(at + Vector2(1, 0), Vector2(5, 5)), AMBER)
		return
	at.y += roundf(sin(_time * arrow_bob_rate * TAU) * arrow_bob)
	for row: int in 4:
		draw_rect(Rect2(at + Vector2(row, row), Vector2(7 - row * 2, 1)), AMBER)


# A small flame beside the choice the cursor is on, and a little arrow
# above or below the list when there's more that way.
func _draw_cursor() -> void:
	var row: int = _selected - _first_shown
	if row < 0 or row >= _choices.get_child_count():
		return
	var label: Control = _choices.get_child(row) as Control
	var middle: float = _choices.position.y + label.position.y + label.size.y / 2.0
	var at: Vector2 = Vector2(_choices.position.x - 11, roundf(middle) - 3)
	var flicker: float = 1.0 if fmod(_time * 6.0, 2.0) < 1.0 else 0.0
	draw_rect(Rect2(at + Vector2(2, -flicker), Vector2(2, 1 + flicker)), AMBER)
	draw_rect(Rect2(at + Vector2(1, 1), Vector2(4, 4)), AMBER)
	draw_rect(Rect2(at + Vector2(0, 2), Vector2(6, 2)), AMBER)
	draw_rect(Rect2(at + Vector2(2, 2), Vector2(2, 2)), FLAME_CORE)
	var right: float = size.x - 16.0
	if _first_shown > 0:
		for step: int in 4:
			draw_rect(Rect2(right + 3 - step, 8 + step, 1 + step * 2, 1), AMBER)
	if _first_shown + shown_count() < _options.size():
		for step: int in 4:
			draw_rect(Rect2(right + step, size.y - 12 + step, 7 - step * 2, 1), AMBER)


# Shows the choices in view, the chosen one brightest.
func _fill_choices() -> void:
	for child: Node in _choices.get_children():
		_choices.remove_child(child)
		child.queue_free()
	for i: int in range(_first_shown, _first_shown + shown_count()):
		var label: Label = Label.new()
		label.text = _options[i]
		label.custom_minimum_size.y = CHOICE_HEIGHT
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_override("font", FONT)
		label.add_theme_font_size_override("font_size", FONT_SIZE)
		label.add_theme_color_override("font_shadow_color", Color(0.02, 0.03, 0.04, 0.9))
		label.add_theme_color_override("font_color",
				SELECTED_COLOR if i == _selected else CHOICE_COLOR)
		_choices.add_child(label)


# Makes the box [param tall], growing upwards from its bottom edge.
func _set_height(tall: float) -> void:
	offset_top = offset_bottom - tall
