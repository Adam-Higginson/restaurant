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
	# TODO 1: _stop_tween(), so an older note's tween can't hide this one.
	# TODO 2: set text to message, set modulate.a to 0.0, and show().
	# TODO 3: _tween = create_tween(), then queue four steps. They run one after
	#         another:
	#         - tween_property(self, "modulate:a", 1.0, fade_seconds)
	#         - tween_interval(show_seconds)        (just waits)
	#         - tween_property(self, "modulate:a", 0.0, fade_seconds)
	#         - tween_callback(hide)                (calls hide() at the end)
	#         No await here: the note looks after itself while the game runs.
	pass


## Hides the note straight away.
func dismiss() -> void:
	# TODO 4: stop the tween and hide().
	pass


func is_showing() -> bool:
	return visible


func _stop_tween() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null
