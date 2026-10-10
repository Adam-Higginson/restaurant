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


## Shows the overlay and fades the screen to black.
func fade_out() -> void:
	show()
	_tween = _new_tween()
	_tween.tween_property(_black, "modulate:a", 1.0, fade_seconds)
	await _tween.finished


## Fades [param text] in over the black screen, in half the fade time.
func show_title(text: String) -> void:
	_title.text = text
	_tween = _new_tween()
	_tween.tween_property(_title, "modulate:a", 1.0, fade_seconds * 0.5)
	await _tween.finished


## Fades the black screen and the title away together, then hides the overlay.
func fade_in() -> void:
	_tween = _new_tween()
	_tween.set_parallel()
	_tween.tween_property(_black, "modulate:a", 0.0, fade_seconds)
	_tween.tween_property(_title, "modulate:a", 0.0, fade_seconds)
	await _tween.finished
	hide()


## Whether the screen is fully black.
func is_covering() -> bool:
	return visible and is_equal_approx(_black.modulate.a, 1.0)


# Stops any fade still running, so two tweens never fight over the same alpha,
# and makes a new one. create_tween() binds it to this node, so it follows this
# node's process mode (Always) and is freed with it.
func _new_tween() -> Tween:
	if _tween != null:
		_tween.kill()
	return create_tween()
