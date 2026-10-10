class_name ConfirmPanel
extends CanvasLayer
## A yes/no question, e.g. "Go to bed?". It pauses the whole game while it's
## open, and tells whoever asked through [signal confirmed] or [signal cancelled].
##
## Display only: the thing that asks (like the bed) decides what Yes does.

## Emitted when the player picks Yes, after the panel has closed.
signal confirmed
## Emitted when the player picks No or presses cancel, after the panel has closed.
signal cancelled

@onready var _question: Label = %Question
@onready var _detail: Label = %Detail
@onready var _yes_button: Button = %YesButton
@onready var _no_button: Button = %NoButton


func _ready() -> void:
	hide()
	_yes_button.pressed.connect(_answer.bind(true))
	_no_button.pressed.connect(_answer.bind(false))


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		# So nothing else also reacts to this Esc press.
		get_viewport().set_input_as_handled()
		_answer(false)


## Shows [param question], with an optional smaller [param detail] line under
## it, and pauses the game until the player answers.
func ask(question: String, detail: String = "") -> void:
	_question.text = question
	_detail.text = detail
	_detail.visible = not detail.is_empty()
	show()
	get_tree().paused = true
	_yes_button.grab_focus()


func is_open() -> bool:
	return visible


func _answer(yes: bool) -> void:
	hide()
	get_tree().paused = false
	if yes:
		confirmed.emit()
	else:
		cancelled.emit()
