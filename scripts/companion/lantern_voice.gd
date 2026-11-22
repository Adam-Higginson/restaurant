class_name LanternVoice
extends Label3D
## What the lantern says: a few words floating beside him, always facing you,
## readable over anything. Each line fades in, stays long enough to read and
## fades away; lines said together wait their turn.

## Emitted when a line has been said and has faded.
signal said(line: String)

## Seconds to read a line: this, plus [member seconds_per_letter] per letter.
@export var base_seconds: float = 1.6
@export var seconds_per_letter: float = 0.055
## Seconds to fade in and out.
@export var fade_seconds: float = 0.3

## The line showing now, or "" when he's quiet.
var saying: String:
	get:
		return _saying

var _saying: String = ""
var _queue: PackedStringArray = PackedStringArray()


func _ready() -> void:
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	no_depth_test = true
	fixed_size = false
	pixel_size = 0.0055
	font_size = 40
	outline_size = 12
	modulate = Color(1.0, 0.92, 0.74, 0.0)
	outline_modulate = Color(0.05, 0.04, 0.03, 0.0)
	width = 620.0
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text = ""


## Says [param line], after anything he's already saying.
func say(line: String) -> void:
	_queue.append(line)
	if _saying.is_empty():
		_next()


## How long [param line] stays up, in seconds, not counting its fades.
func read_seconds(line: String) -> float:
	return base_seconds + seconds_per_letter * line.length()


func _next() -> void:
	if _queue.is_empty():
		_saying = ""
		text = ""
		return
	_saying = _queue[0]
	_queue.remove_at(0)
	text = _saying
	var tween: Tween = create_tween()
	tween.set_parallel()
	tween.tween_property(self, "modulate:a", 1.0, fade_seconds)
	tween.tween_property(self, "outline_modulate:a", 1.0, fade_seconds)
	tween.chain().tween_interval(read_seconds(_saying))
	tween.chain().tween_property(self, "modulate:a", 0.0, fade_seconds)
	tween.parallel().tween_property(self, "outline_modulate:a", 0.0, fade_seconds)
	var line: String = _saying
	tween.chain().tween_callback(func() -> void:
		said.emit(line)
		_next())
