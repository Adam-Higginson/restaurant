class_name LookChoice
extends CanvasLayer
## "Who are you?": a boy or a girl, asked once when a new voyage begins, over
## the black before the opening cutscene. It says which through
## [signal chosen]; the [Opening] asking it puts the answer into the game.
##
## Display only: it doesn't change the game itself.

## Emitted when the player picks, after the screen has closed.
signal chosen(body: PlayerLook.Body)

@onready var _boy_button: Button = %BoyButton
@onready var _girl_button: Button = %GirlButton


func _ready() -> void:
	hide()
	_boy_button.pressed.connect(choose.bind(PlayerLook.Body.BOY))
	_girl_button.pressed.connect(choose.bind(PlayerLook.Body.GIRL))


## Shows the question, with the first answer ready to press.
func ask() -> void:
	show()
	# The camera holds the mouse; let it go so the buttons can be clicked.
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_boy_button.grab_focus()


## Whether the question is showing.
func is_open() -> bool:
	return visible


## Answers the question with [param body] and closes it. Pressing a button
## does this.
func choose(body: PlayerLook.Body) -> void:
	if not visible:
		return
	hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	chosen.emit(body)
