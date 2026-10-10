class_name Notice
extends Label
## A short note at the top of the screen, e.g. "Getting late…". It fades in,
## stays for a few seconds, then fades away by itself.
##
## Display only: gameplay code decides when to show a note and what it says.

const FADE_SECONDS: float = 0.4
const SHOW_SECONDS: float = 3.0

## How long fading in or out takes. Tests make it shorter.
var fade_seconds: float = FADE_SECONDS
## How long the note stays fully shown. Tests make it shorter.
var show_seconds: float = SHOW_SECONDS

# The note's fade running now, if any, so a new note can stop it first.
var _tween: Tween = null


func _ready() -> void:
	hide()


## Shows [param message], replacing any note already showing.
func show_message(message: String) -> void:
	_stop_tween()

	text = message
	modulate.a = 0.0
	show()

	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, fade_seconds)
	_tween.tween_interval(show_seconds)
	_tween.tween_property(self, "modulate:a", 0.0, fade_seconds)
	_tween.tween_callback(hide)


## Hides the note straight away.
func dismiss() -> void:
	_stop_tween()
	hide()


func is_showing() -> bool:
	return visible


func _stop_tween() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null
