class_name DoorSign
extends StaticBody2D
## The sign by the door: Interact flips the restaurant between Open and
## Closed. It shows green while open and red while closed, whatever changed it.

const FRAME_COLOR: Color = Color(0.4, 0.3, 0.22, 1)
const OPEN_COLOR: Color = Color(0.36, 0.7, 0.38, 1)
const CLOSED_COLOR: Color = Color(0.72, 0.32, 0.3, 1)
## The whole 16x16 tile, centred on the sign's position.
const FRAME_RECT: Rect2 = Rect2(-8, -8, 16, 16)
## The coloured board, inset 2px inside the frame.
const BOARD_RECT: Rect2 = Rect2(-6, -6, 12, 12)

## The state the sign flips. Tests set their own before adding the sign;
## otherwise it's the [code]Game[/code] autoload.
var game_state: GameState = null

@onready var _interactable: Interactable = $Interactable


func _ready() -> void:
	if game_state == null:
		game_state = Game
	_interactable.interacted.connect(_on_interacted)
	game_state.open_changed.connect(_on_open_changed)


func _draw() -> void:
	draw_rect(FRAME_RECT, FRAME_COLOR)
	draw_rect(BOARD_RECT, OPEN_COLOR if game_state.is_open else CLOSED_COLOR)


## Opens the restaurant if it's closed, and closes it if it's open.
func flip() -> void:
	game_state.set_open(not game_state.is_open)


func _on_interacted(_player: Player) -> void:
	flip()


func _on_open_changed(_is_open: bool) -> void:
	queue_redraw()
