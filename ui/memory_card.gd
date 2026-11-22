class_name MemoryCard
extends Control
## Shows a memory of home as it comes back: a soft panel at the top middle
## of the screen, its title first, then each line fading in after the last.
## It lingers, then fades away. Memories that come back together wait their
## turn. Listens to the [MemoryBook] in [GameState].

## Emitted when a memory has been shown and has faded away.
signal finished(memory: Memory)

## Seconds between one line and the next fading in.
@export var line_seconds: float = 1.3
## Seconds it stays once every line is showing.
@export var hold_seconds: float = 4.0
## Seconds to fade in and out.
@export var fade_seconds: float = 0.9

## The memory showing now, or null.
var showing: Memory:
	get:
		return _showing

var _showing: Memory = null
var _queue: Array[Memory] = []
var _panel: PanelContainer = null
var _list: VBoxContainer = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_to_group(&"memory_card")
	_build()
	Game.memories.remembered.connect(show_memory)


## Shows a card with [param title] and [param lines] (a page of the recipe
## book, say), after any already showing or waiting.
func show_card(title: String, lines: PackedStringArray) -> void:
	var page: Memory = Memory.new()
	page.title = title
	page.lines = lines
	show_memory(page)


## Shows [param memory], after any already showing or waiting.
func show_memory(memory: Memory) -> void:
	_queue.append(memory)
	if _showing == null:
		_next()


## The text showing now, title and lines, for tests and the editor.
func shown_text() -> PackedStringArray:
	var text: PackedStringArray = PackedStringArray()
	for child: Node in _list.get_children():
		var label: Label = child as Label
		if label != null and label.modulate.a > 0.0:
			text.append(label.text)
	return text


func _next() -> void:
	if _queue.is_empty():
		_showing = null
		_panel.hide()
		return
	_showing = _queue.pop_front()
	for child: Node in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	var labels: Array[Label] = [_label(_showing.title, true)]
	for line: String in _showing.lines:
		labels.append(_label(line, false))
	_panel.modulate.a = 0.0
	_panel.show()
	var tween: Tween = create_tween()
	tween.tween_property(_panel, "modulate:a", 1.0, fade_seconds)
	for label: Label in labels:
		tween.tween_property(label, "modulate:a", 1.0, fade_seconds)
		tween.tween_interval(line_seconds - fade_seconds)
	tween.tween_interval(hold_seconds)
	tween.tween_property(_panel, "modulate:a", 0.0, fade_seconds)
	var done: Memory = _showing
	tween.tween_callback(func() -> void:
		finished.emit(done)
		_next())


func _label(text: String, is_title: bool) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(1, 0)
	label.modulate.a = 0.0
	if is_title:
		label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.45))
		label.add_theme_font_size_override("font_size", 12)
	else:
		label.add_theme_color_override("font_color", Color(0.93, 0.89, 0.8))
		label.add_theme_font_size_override("font_size", 8)
	_list.add_child(label)
	return label


func _build() -> void:
	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.04, 0.06, 0.62)
	style.set_corner_radius_all(4)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 10.0
	_panel.add_theme_stylebox_override("panel", style)
	# The middle three fifths of the screen, near the top, so you can still
	# see yourself and the lantern.
	_panel.anchor_left = 0.2
	_panel.anchor_right = 0.8
	_panel.offset_top = 18.0
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 3)
	_panel.add_child(_list)
	add_child(_panel)
	_panel.hide()
