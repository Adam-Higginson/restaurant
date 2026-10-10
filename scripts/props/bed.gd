class_name Bed
extends StaticBody2D
## The bed in the back room: Interact asks "Go to bed?", and Yes ends the day.

## Added under the question when going to bed would close the restaurant.
const CLOSING_NOTE: String = "The restaurant will close."
const FRAME_COLOR: Color = Color(0.4, 0.3, 0.22, 1)
const PILLOW_COLOR: Color = Color(0.93, 0.91, 0.86, 1)
const BLANKET_COLOR: Color = Color(0.36, 0.5, 0.72, 1)
const FOLD_COLOR: Color = Color(0.55, 0.67, 0.84, 1)
## The bed is 16 x 32, centred on the node, with the pillow at the top.
const FRAME_RECT: Rect2 = Rect2(-8, -16, 16, 32)
const PILLOW_RECT: Rect2 = Rect2(-6, -14, 12, 7)
const BLANKET_RECT: Rect2 = Rect2(-7, -5, 14, 20)
const FOLD_RECT: Rect2 = Rect2(-7, -5, 14, 3)

## The state whose day ends. Tests set their own before adding the bed;
## otherwise it's the [code]Game[/code] autoload.
var game_state: GameState = null

@onready var _interactable: Interactable = $Interactable
@onready var _confirm_panel: ConfirmPanel = $ConfirmPanel


func _ready() -> void:
	if game_state == null:
		game_state = Game
	_interactable.interacted.connect(_on_interacted)
	_confirm_panel.confirmed.connect(game_state.end_day)


func _draw() -> void:
	draw_rect(FRAME_RECT, FRAME_COLOR)
	draw_rect(PILLOW_RECT, PILLOW_COLOR)
	draw_rect(BLANKET_RECT, BLANKET_COLOR)
	# A folded-back strip where the blanket meets the pillow.
	draw_rect(FOLD_RECT, FOLD_COLOR)


func ask_to_sleep() -> void:
	var detail: String = CLOSING_NOTE if game_state.is_open else ""
	_confirm_panel.ask("Go to bed?", detail)


func _on_interacted(_player: Player) -> void:
	ask_to_sleep()
