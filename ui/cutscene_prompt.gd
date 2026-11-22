class_name CutscenePrompt
extends CanvasLayer
## The words at the bottom of the screen while a cutscene waits for the
## player: "[E] Take his hand", or "Press any button". They come in gently a
## moment after the wait begins, then breathe, so a quiet scene has a beat
## to itself before it asks for anything.
##
## Display only: [WaitCues] says when to show it and what it says.

## How long after the wait begins the words start to appear, in seconds.
@export var delay_seconds: float = 1.2
## How long they take to fade in and out, in seconds.
@export var fade_seconds: float = 0.8
## How dim the words get as they breathe: 1 doesn't dim at all.
@export_range(0.0, 1.0) var breathe_to: float = 0.55

## Whether a prompt is up (or on its way up).
var is_prompting: bool:
	get:
		return _prompting

var _prompting: bool = false
var _tween: Tween = null
## Whose button names to show: the last device used.
var _device: ActionPrompt.Device = ActionPrompt.Device.KEYBOARD_MOUSE

@onready var _label: Label = %Words


func _ready() -> void:
	_label.modulate.a = 0.0
	hide()


func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouseButton:
		_device = ActionPrompt.Device.KEYBOARD_MOUSE
	elif event is InputEventJoypadButton:
		_device = ActionPrompt.Device.PAD


## Shows [param words] after a moment. With [param names_interact], the
## Interact button's name goes first: "[E] Take his hand".
func show_prompt(words: String, names_interact: bool = false) -> void:
	_prompting = true
	_label.text = prompt_text(words, names_interact, _device)
	_label.modulate.a = 0.0
	show()
	_tween = _new_tween()
	_tween.tween_interval(delay_seconds)
	_tween.tween_property(_label, "modulate:a", 1.0, fade_seconds)
	_tween.tween_callback(_breathe)


## Fades the words away.
func hide_prompt() -> void:
	if not _prompting:
		return
	_prompting = false
	_tween = _new_tween()
	_tween.tween_property(_label, "modulate:a", 0.0, fade_seconds * 0.5)
	_tween.tween_callback(hide)


## What's written on the screen now, or "" when nothing is.
func shown_text() -> String:
	return _label.text if _prompting else ""


## The words of a prompt: [param words], after the Interact button's name on
## device [param on] if [param names_interact].
static func prompt_text(words: String, names_interact: bool, on: ActionPrompt.Device) -> String:
	if not names_interact:
		return words
	return "[%s] %s" % [ActionPrompt.button_name(&"interact", on), words]


# Dims and brightens the words for as long as they're up.
func _breathe() -> void:
	if not _prompting:
		return
	_tween = _new_tween()
	_tween.set_loops()
	_tween.tween_property(_label, "modulate:a", breathe_to, 1.1).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(_label, "modulate:a", 1.0, 1.1).set_trans(Tween.TRANS_SINE)


func _new_tween() -> Tween:
	if _tween != null:
		_tween.kill()
	return create_tween()
