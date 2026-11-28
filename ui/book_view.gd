class_name BookView
extends Control
## The open book you read in (#145). Play pauses, the world dims, and the
## book lies open across the screen: two pages of painted paper in a leather
## cover, the words in ink. Left and right turn the pages; Interact (or
## Cancel) closes it.
##
## Display only: which pages are open is a [BookReading]'s business. Props
## open a book with [method open], finding this view through its group.

## Emitted when a book is opened.
signal opened(book: Book)
## Emitted when the book is closed.
signal closed(book: Book)
## Emitted when a page is turned, forward or back.
signal page_turned

## The group the view is in, so a prop can find it.
const GROUP: StringName = &"book_view"
## The old-book face the words are set in (IM Fell English, SIL Open Font
## Licence), cut from the Fell types of the 1670s.
const FONT: Font = preload("res://assets/fonts/book_font.tres")
## The sizes the words of a page may be set at, largest first: a page too full
## for one is set at the next.
const BODY_SIZES: Array[int] = [11, 10, 9]
const HEADING_SIZE: int = 15
const NUMBER_SIZE: int = 8
## The space between one paragraph and the next, and under the heading.
const LINE_GAP: int = 4
## Where the words go on each page: the space between the page's ink rules.
const TEXT_SIZE: Vector2 = Vector2(148, 164)
## Ink, and the red-brown the headings are picked out in, as old books did.
const INK: Color = Color(0.22, 0.13, 0.07)
const RUBRIC: Color = Color(0.48, 0.14, 0.08)

## The page sounds (Kenney's RPG Audio, CC0), each at the volume that sits it
## level with the conversation's clicks.
const OPEN_SOUND: AudioStream = preload("res://assets/audio/ui/bookOpen.ogg")
const OPEN_DB: float = 2.0
const CLOSE_SOUND: AudioStream = preload("res://assets/audio/ui/bookClose.ogg")
const CLOSE_DB: float = -14.0
const FLIP_SOUNDS: Array[AudioStream] = [
	preload("res://assets/audio/ui/bookFlip2.ogg"),
	preload("res://assets/audio/ui/bookFlip3.ogg"),
]
const FLIP_DB: Array[float] = [5.0, 0.0]

## How long the book takes to come up and go away, in seconds.
@export var fade_seconds: float = 0.25

## What's open now, or null when no book is.
var reading: BookReading:
	get:
		return _reading

var _reading: BookReading = null
var _player: Player3D = null
## The frame the book opened on: the press that opened it mustn't close it.
var _opened_frame: int = -1
var _tween: Tween = null
var _device: ActionPrompt.Device = ActionPrompt.Device.KEYBOARD_MOUSE
var _last_flip: int = -1
## The page-turning directions being held now.
var _held: Dictionary[StringName, bool] = {}

@onready var _left_heading: Label = %LeftHeading
@onready var _left_lines: VBoxContainer = %LeftLines
@onready var _left_picture: TextureRect = %LeftPicture
@onready var _left_number: Label = %LeftNumber
@onready var _right_heading: Label = %RightHeading
@onready var _right_lines: VBoxContainer = %RightLines
@onready var _right_picture: TextureRect = %RightPicture
@onready var _right_number: Label = %RightNumber
@onready var _prompt: Label = %Prompt
@onready var _sound: AudioStreamPlayer = %Sound


func _ready() -> void:
	add_to_group(GROUP)
	for heading: Label in [_left_heading, _right_heading]:
		heading.add_theme_font_override("font", FONT)
		heading.add_theme_font_size_override("font_size", HEADING_SIZE)
		heading.add_theme_color_override("font_color", RUBRIC)
	for number: Label in [_left_number, _right_number]:
		number.add_theme_font_override("font", FONT)
		number.add_theme_font_size_override("font_size", NUMBER_SIZE)
		number.add_theme_color_override("font_color", INK)
	hide()


func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouseButton:
		_set_device(ActionPrompt.Device.KEYBOARD_MOUSE)
	elif event is InputEventJoypadButton or (event is InputEventJoypadMotion
			and absf((event as InputEventJoypadMotion).axis_value) > ActionPrompt.STICK_THRESHOLD):
		_set_device(ActionPrompt.Device.PAD)


func _unhandled_input(event: InputEvent) -> void:
	if not is_open() or not InteractionDetector3D.accepts_event(event, Input.mouse_mode):
		return
	# The press that opened the book mustn't close it again.
	if Engine.get_process_frames() == _opened_frame:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_cancel") \
			or (_reading.book.title == "Journal" and event.is_action_pressed("journal")):
		get_viewport().set_input_as_handled()
		close()
	elif _newly_pushed(event, &"move_right") or _newly_pushed(event, &"ui_right"):
		get_viewport().set_input_as_handled()
		turn_forward()
	elif _newly_pushed(event, &"move_left") or _newly_pushed(event, &"ui_left"):
		get_viewport().set_input_as_handled()
		turn_back()


## The world's book view, looked for from [param from], or null if there's
## none.
static func find(from: Node) -> BookView:
	if from == null or not from.is_inside_tree():
		return null
	return from.get_tree().get_first_node_in_group(GROUP) as BookView


## Opens [param book] at its first pages for [param player], whose controls
## are off until it's closed. Returns whether it opened: not while another
## book is open.
func open(book: Book, player: Player3D = null) -> bool:
	if is_open() or book == null:
		return false
	_reading = BookReading.new(book)
	_player = player
	if is_instance_valid(_player):
		_player.controls_enabled = false
	_opened_frame = Engine.get_process_frames()
	_held.clear()
	_show_pages()
	_refresh_prompt()
	_play(OPEN_SOUND, OPEN_DB)
	modulate.a = 0.0
	show()
	_fade_to(1.0)
	opened.emit(book)
	return true


## Closes the book and gives the player their controls back.
func close() -> void:
	if not is_open():
		return
	var book: Book = _reading.book
	_reading = null
	if is_instance_valid(_player):
		_player.controls_enabled = true
	_player = null
	_play(CLOSE_SOUND, CLOSE_DB)
	_fade_to(0.0).tween_callback(hide)
	closed.emit(book)


func is_open() -> bool:
	return _reading != null


## Turns to the next two pages. Returns whether it turned.
func turn_forward() -> bool:
	return is_open() and _turned(_reading.turn_forward())


## Turns back two pages. Returns whether it turned.
func turn_back() -> bool:
	return is_open() and _turned(_reading.turn_back())


## The words showing on the open pages, headings first, for tests.
func shown_text() -> PackedStringArray:
	var text: PackedStringArray = PackedStringArray()
	if not is_open():
		return text
	_append_shown(text, _left_heading, _left_lines)
	_append_shown(text, _right_heading, _right_lines)
	return text


## The size [param page]'s words are set at: the largest of [constant
## BODY_SIZES] they fit the page at, or the smallest if none fits.
static func body_size_for(page: BookPage) -> int:
	for size: int in BODY_SIZES:
		if page_height(page, size) <= TEXT_SIZE.y:
			return size
	return BODY_SIZES[BODY_SIZES.size() - 1]


## How tall [param page] stands with its words at [param body_size].
static func page_height(page: BookPage, body_size: int) -> float:
	var width: float = TEXT_SIZE.x
	var height: float = 0.0
	if not page.heading.is_empty():
		height += FONT.get_multiline_string_size(page.heading, HORIZONTAL_ALIGNMENT_CENTER,
				width, HEADING_SIZE).y + LINE_GAP
	for line: String in page.lines:
		height += FONT.get_multiline_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, width,
				body_size).y + LINE_GAP
	if page.picture != null:
		height += page.picture.get_height() + LINE_GAP
	return height


## Whether [param page] fits its paper at the smallest size.
static func fits(page: BookPage) -> bool:
	return page_height(page, BODY_SIZES[BODY_SIZES.size() - 1]) <= TEXT_SIZE.y


# Whether [param event] pushes [param action] from let go to held. A stick
# held over sends a stream of events; only the first of them turns a page.
func _newly_pushed(event: InputEvent, action: StringName) -> bool:
	if event.is_action_released(action):
		_held.erase(action)
		return false
	if not event.is_action_pressed(action) or _held.has(action):
		return false
	_held[action] = true
	return true


func _turned(did_turn: bool) -> bool:
	if not did_turn:
		return false
	_show_pages()
	# Never the same rustle twice running.
	var flip: int = randi() % FLIP_SOUNDS.size()
	if flip == _last_flip:
		flip = (flip + 1) % FLIP_SOUNDS.size()
	_last_flip = flip
	_play(FLIP_SOUNDS[flip], FLIP_DB[flip])
	page_turned.emit()
	return true


func _show_pages() -> void:
	var left_number: int = _reading.left_index + 1
	_show_page(_reading.left_page(), _left_heading, _left_lines, _left_picture)
	_show_page(_reading.right_page(), _right_heading, _right_lines, _right_picture)
	_left_number.text = str(left_number) if _reading.left_page() != null else ""
	_right_number.text = str(left_number + 1) if _reading.right_page() != null else ""


func _show_page(page: BookPage, heading: Label, lines: VBoxContainer,
		picture: TextureRect) -> void:
	for child: Node in lines.get_children():
		lines.remove_child(child)
		child.queue_free()
	heading.visible = page != null and not page.heading.is_empty()
	picture.visible = page != null and page.picture != null
	if page == null:
		return
	heading.text = page.heading
	picture.texture = page.picture
	var size: int = body_size_for(page)
	for text: String in page.lines:
		var line: Label = Label.new()
		line.text = text
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.custom_minimum_size = Vector2(1, 0)
		line.add_theme_font_override("font", FONT)
		line.add_theme_font_size_override("font_size", size)
		line.add_theme_color_override("font_color", INK)
		lines.add_child(line)


func _append_shown(text: PackedStringArray, heading: Label, lines: VBoxContainer) -> void:
	if heading.visible:
		text.append(heading.text)
	for child: Node in lines.get_children():
		var line: Label = child as Label
		if line != null and not line.is_queued_for_deletion():
			text.append(line.text)


func _set_device(device: ActionPrompt.Device) -> void:
	if device == _device:
		return
	_device = device
	_refresh_prompt()


func _refresh_prompt() -> void:
	if not is_node_ready():
		return
	var turn: String = "Stick" if _device == ActionPrompt.Device.PAD else "%s/%s" % [
			ActionPrompt.button_name(&"move_left", _device),
			ActionPrompt.button_name(&"move_right", _device)]
	var action: StringName = &"journal" if _reading != null \
			and _reading.book.title == "Journal" else &"interact"
	_prompt.text = "[%s] Turn the page      [%s] Close" % [
			turn, ActionPrompt.button_name(action, _device)]


func _play(sound: AudioStream, volume_db: float) -> void:
	_sound.stream = sound
	_sound.volume_db = volume_db
	_sound.play()


func _fade_to(alpha: float) -> Tween:
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", alpha, fade_seconds)
	return _tween
