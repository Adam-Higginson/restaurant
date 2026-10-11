class_name ContainerPanel
extends CanvasLayer
## Lists what's in a container (the fridge, the cupboard, the delivery crate),
## one row per item and quality ("Tomato ★ ×2"). Picking a row moves one onto
## the player's arms. It pauses the whole game while it's open.
##
## Display only: [StorageContents] does the moving, and the panel redraws from
## its signals and the arms'.

## Emitted after the panel has closed.
signal closed

const FONT_SIZE: int = 8

var _contents: StorageContents = null
var _arms: Arms = null

@onready var _title: Label = %Title
@onready var _rows: VBoxContainer = %Rows
@onready var _status: Label = %Status
@onready var _close_button: Button = %CloseButton


func _ready() -> void:
	hide()
	_close_button.pressed.connect(close)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		# So nothing else also reacts to this Esc press.
		get_viewport().set_input_as_handled()
		close()


## Shows [param contents] under [param title], taking into [param arms], and
## pauses the game until it's closed.
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
