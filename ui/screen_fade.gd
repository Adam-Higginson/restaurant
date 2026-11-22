class_name ScreenFade
extends CanvasLayer
## A full-screen black fade with a title card on top, e.g. for going to sleep.
##
## Display only: the day cycle decides when to fade and what the title says.
## Each method runs its own Tween and returns once it's finished, so callers
## can [code]await[/code] them one after another. It keeps running while the
## game is paused.

const FADE_SECONDS: float = 0.8

## How long each fade takes. Tests make it shorter.
var fade_seconds: float = FADE_SECONDS

# The fade running now, if any, so a new one can stop it first.
var _tween: Tween = null

@onready var _black: ColorRect = %Black
@onready var _title: Label = %Title


func _ready() -> void:
	hide()
	_black.modulate.a = 0.0
	_title.modulate.a = 0.0


## Shows the overlay and fades the screen to black, over [param seconds]
## (or [member fade_seconds] if not given).
func fade_out(seconds: float = -1.0) -> void:
	show()
	_tween = _new_tween()
	_tween.tween_property(_black, "modulate:a", 1.0, _seconds_or_usual(seconds))
	await _tween.finished


## Fades [param text] in over the black screen, in half the fade time.
func show_title(text: String) -> void:
	_title.text = text
	_tween = _new_tween()
	_tween.tween_property(_title, "modulate:a", 1.0, fade_seconds * 0.5)
	await _tween.finished


## Fades the black screen and the title away together, over [param seconds]
## (or [member fade_seconds] if not given), then hides the overlay.
func fade_in(seconds: float = -1.0) -> void:
	var time: float = _seconds_or_usual(seconds)
	_tween = _new_tween()
	_tween.set_parallel()
	_tween.tween_property(_black, "modulate:a", 0.0, time)
	_tween.tween_property(_title, "modulate:a", 0.0, time)
	await _tween.finished
	hide()


## Makes the screen black at once, with no fade: for the very first frame,
## or when a cutscene is skipped. Any title showing stays.
func cover_now() -> void:
	if _tween != null:
		_tween.kill()
	_black.modulate.a = 1.0
	show()


## Uncovers the screen at once, with no fade, and puts any title away.
func uncover_now() -> void:
	if _tween != null:
		_tween.kill()
	_black.modulate.a = 0.0
	_title.modulate.a = 0.0
	hide()


## Whether the screen is fully black.
func is_covering() -> bool:
	return visible and is_equal_approx(_black.modulate.a, 1.0)


func _seconds_or_usual(seconds: float) -> float:
	return seconds if seconds >= 0.0 else fade_seconds


# Stops any fade still running, so two tweens never fight over the same alpha,
# and makes a new one. create_tween() binds it to this node, so it follows this
# node's process mode (Always) and is freed with it.
func _new_tween() -> Tween:
	if _tween != null:
		_tween.kill()
	return create_tween()
