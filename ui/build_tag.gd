class_name BuildTag
extends CanvasLayer
## Which build this is ("2026.11.23 (a1b2c3d)", or "dev" from the editor),
## small and faint in the corner of the title, so a player can say which
## build they played.
##
## Display only: [WaitCues] says when to show it (while the title waits for
## a button), and [BuildInfo] says what it says.

## How long it takes to fade in and out, in seconds.
@export var fade_seconds: float = 0.8
## How strongly it shows: faint, so it never competes with the title.
@export_range(0.0, 1.0) var opacity: float = 0.45

## Whether it's up (or on its way up).
var is_showing: bool:
	get:
		return _showing

var _showing: bool = false
var _tween: Tween = null

@onready var _label: Label = %Words


func _ready() -> void:
	_label.text = BuildInfo.label()
	_label.modulate.a = 0.0
	hide()


## Fades the tag in.
func show_tag() -> void:
	_showing = true
	show()
	_tween = _new_tween()
	_tween.tween_property(_label, "modulate:a", opacity, fade_seconds)


## Fades the tag away.
func hide_tag() -> void:
	if not _showing:
		return
	_showing = false
	_tween = _new_tween()
	_tween.tween_property(_label, "modulate:a", 0.0, fade_seconds * 0.5)
	_tween.tween_callback(hide)


## What's written in the corner now, or "" when nothing is.
func shown_text() -> String:
	return _label.text if _showing else ""


func _new_tween() -> Tween:
	if _tween != null:
		_tween.kill()
	return create_tween()
