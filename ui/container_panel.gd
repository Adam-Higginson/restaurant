class_name ContainerPanel
extends CanvasLayer
## Lists what's in a container (the galley pantry; once, the fridge and cupboard),
## one row per item and quality ("Tomato ★ ×2"). Picking a row moves one onto
## the player's arms. It pauses the whole game while it's open, and shows the
## mouse cursor (the 3D camera captures it) until it closes.
##
## Display only: [StorageContents] does the moving, and the panel redraws from
## its signals and the arms'.

## Emitted after the panel has closed.
signal closed

const FONT_SIZE: int = 8
## The pantry's look (#207): a painted wood back, shelves for rows, and a
## paper label for its name.
const WOOD: Texture2D = preload("res://assets/placeholder/textures/weathered_wood.png")
const WOOD_TINT: Color = Color(0.85, 0.62, 0.42)
const SHELF: Color = Color(0.5, 0.33, 0.19)
const SHELF_LIT: Color = Color(0.64, 0.44, 0.26)
const SHELF_LIP: Color = Color(0.24, 0.14, 0.08)
const PAPER: Color = Color(0.93, 0.87, 0.72)
const INK: Color = Color(0.3, 0.18, 0.1)
const CREAM: Color = Color(0.98, 0.93, 0.82)
const BRASS: Color = Color(0.9, 0.7, 0.35)

var _contents: StorageContents = null
var _arms: Arms = null
## The mouse mode before opening, put back on closing.
var _mouse_mode_before: Input.MouseMode = Input.MOUSE_MODE_VISIBLE

@onready var _title: Label = %Title
@onready var _rows: VBoxContainer = %Rows
@onready var _status: Label = %Status
@onready var _close_button: Button = %CloseButton
@onready var _panel: PanelContainer = $Panel


func _ready() -> void:
	hide()
	_close_button.pressed.connect(close)
	_dress()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		# So nothing else also reacts to this Esc press.
		get_viewport().set_input_as_handled()
		close()


## Shows [param contents] under [param title], taking into [param arms], and
## pauses the game and frees the mouse until it's closed.
func open(title: String, contents: StorageContents, arms: Arms) -> void:
	if visible:
		return
	_title.text = title
	_contents = contents
	_arms = arms
	_contents.changed.connect(_refresh)
	_arms.changed.connect(_refresh)
	show()
	get_tree().paused = true
	_mouse_mode_before = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_refresh()


func close() -> void:
	if not visible:
		return
	_contents.changed.disconnect(_refresh)
	_arms.changed.disconnect(_refresh)
	_contents = null
	_arms = null
	hide()
	get_tree().paused = false
	Input.mouse_mode = _mouse_mode_before
	closed.emit()


func is_open() -> bool:
	return visible


## The row buttons, top first.
func get_rows() -> Array[Button]:
	var buttons: Array[Button] = []
	for child: Node in _rows.get_children():
		if not child.is_queued_for_deletion():
			buttons.append(child as Button)
	return buttons


## The text of a row for [param count] pieces of [param item] at [param quality].
static func describe(item: Item, quality: int, count: int) -> String:
	return "%s %s ×%d" % [item.display_name, "★".repeat(quality), count]


func _refresh() -> void:
	var focused: int = _focused_row()
	for button: Button in get_rows():
		_rows.remove_child(button)
		button.queue_free()

	var arms_full: bool = _arms.is_full()
	for piece: ItemInstance in _distinct_pieces():
		var button: Button = Button.new()
		button.text = describe(piece.item, piece.quality, _contents.count(piece.item, piece.quality))
		button.add_theme_font_size_override("font_size", FONT_SIZE)
		dress_shelf(button)
		button.disabled = arms_full
		button.pressed.connect(_contents.take_into.bind(_arms, piece.item, piece.quality))
		_rows.add_child(button)

	if _contents.is_empty():
		_status.text = "Empty"
	elif arms_full:
		_status.text = "Arms full"
	else:
		_status.text = ""
	_status.visible = not _status.text.is_empty()
	_restore_focus(focused)


# One piece for each item and quality inside, in the order they arrived.
func _distinct_pieces() -> Array[ItemInstance]:
	var seen: Dictionary[String, bool] = {}
	var pieces: Array[ItemInstance] = []
	for piece: ItemInstance in _contents.get_items():
		var key: String = "%s:%d" % [piece.item.get_instance_id(), piece.quality]
		if not seen.has(key):
			seen[key] = true
			pieces.append(piece)
	return pieces


func _focused_row() -> int:
	var rows: Array[Button] = get_rows()
	for i: int in rows.size():
		if rows[i].has_focus():
			return i
	return 0


# Keeps focus near where it was, so taking the last of a row moves the D-pad
# cursor to its neighbour rather than losing it. With nothing to take, the
# Close button gets it.
func _restore_focus(index: int) -> void:
	var enabled: Array[Button] = []
	for button: Button in get_rows():
		if not button.disabled:
			enabled.append(button)
	if enabled.is_empty():
		_close_button.grab_focus()
	else:
		enabled[mini(index, enabled.size() - 1)].grab_focus()


## Styles [param button] as a shelf in the pantry: a plank with a dark lip
## under it, lighter when it's pointed at or picked, and a brass edge when
## it's the one a controller would pick.
static func dress_shelf(button: Button) -> void:
	button.add_theme_stylebox_override(&"normal", _plank(SHELF, SHELF_LIP))
	button.add_theme_stylebox_override(&"hover", _plank(SHELF_LIT, SHELF_LIP))
	button.add_theme_stylebox_override(&"pressed", _plank(SHELF_LIT, BRASS))
	button.add_theme_stylebox_override(&"focus", _edge(BRASS))
	button.add_theme_stylebox_override(&"disabled", _plank(SHELF.darkened(0.3), SHELF_LIP))
	for state: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color",
			&"font_focus_color"]:
		button.add_theme_color_override(state, CREAM)
	button.add_theme_color_override(&"font_disabled_color", CREAM.darkened(0.45))
	button.add_theme_color_override(&"font_outline_color", SHELF_LIP)
	button.add_theme_constant_override(&"outline_size", 2)


# The wood back, the paper label on top, and the shelves.
func _dress() -> void:
	var back: StyleBoxTexture = StyleBoxTexture.new()
	back.texture = WOOD
	back.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	back.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	back.modulate_color = WOOD_TINT
	back.set_content_margin_all(6.0)
	_panel.add_theme_stylebox_override(&"panel", back)
	var label: StyleBoxFlat = StyleBoxFlat.new()
	label.bg_color = PAPER
	label.border_color = INK
	label.set_border_width_all(1)
	label.set_corner_radius_all(1)
	label.content_margin_left = 6.0
	label.content_margin_right = 6.0
	label.content_margin_top = 1.0
	label.content_margin_bottom = 1.0
	_title.add_theme_stylebox_override(&"normal", label)
	_title.add_theme_color_override(&"font_color", INK)
	_status.add_theme_color_override(&"font_color", CREAM)
	_status.add_theme_color_override(&"font_outline_color", SHELF_LIP)
	_status.add_theme_constant_override(&"outline_size", 2)
	dress_shelf(_close_button)


static func _plank(colour: Color, lip: Color) -> StyleBoxFlat:
	var plank: StyleBoxFlat = StyleBoxFlat.new()
	plank.bg_color = colour
	plank.border_color = lip
	plank.border_width_bottom = 2
	plank.content_margin_left = 6.0
	plank.content_margin_right = 6.0
	plank.content_margin_top = 2.0
	plank.content_margin_bottom = 3.0
	return plank


static func _edge(colour: Color) -> StyleBoxFlat:
	var edge: StyleBoxFlat = StyleBoxFlat.new()
	edge.draw_center = false
	edge.border_color = colour
	edge.set_border_width_all(1)
	return edge
