class_name DayCycle
extends Node
## Runs the day: moves the clock on with real time, nudges the player at
## midnight, and plays the night when the day ends.
##
## The night: the screen fades to black, the next day starts, the player
## wakes at the wake spot, the new date shows, and the screen fades back in.
## The game is paused throughout, so nobody moves in the dark.

## Emitted once the screen has faded back in on a new day and the game runs
## again.
signal morning_started

## How long the new date stays on screen.
const TITLE_SECONDS: float = 1.5
## Midnight, in minutes since the midnight the day started on.
const MIDNIGHT_MINUTES: int = 24 * 60
const LATE_MESSAGE: String = "Getting late…"

## Moved to [member wake_spot] each morning. Optional.
@export var player: Node2D = null
@export var wake_spot: Marker2D = null
@export var screen_fade: ScreenFade = null
## Shows the midnight note. Optional.
@export var notice: Notice = null

## The state whose clock this runs. Tests set their own before adding it;
## otherwise it's the [code]Game[/code] autoload.
var game_state: GameState = null
## How long the new date stays on screen. Tests make it shorter.
var title_seconds: float = TITLE_SECONDS

var _is_night: bool = false


func _ready() -> void:
	if game_state == null:
		game_state = Game
	game_state.day_ended.connect(_on_day_ended)
	game_state.clock.time_changed.connect(_on_time_changed)


func _process(delta: float) -> void:
	game_state.clock.tick(delta)


## Whether the night is playing, from the day ending until morning.
func is_night() -> bool:
	return _is_night


func _on_day_ended(_day: int) -> void:
	if _is_night:
		return
	_is_night = true
	if notice != null:
		notice.dismiss()
	# Paused so nobody moves in the dark. The fade runs anyway (process mode
	# Always), and scene-tree timers keep counting while paused.
	get_tree().paused = true

	await screen_fade.fade_out()
	# Behind the black screen, so the player never sees the jump.
	game_state.start_next_day()
	_wake_player()
	await screen_fade.show_title(Calendar.format_date(game_state.day))
	await get_tree().create_timer(title_seconds).timeout
	await screen_fade.fade_in()

	get_tree().paused = false
	_is_night = false
	morning_started.emit()


func _wake_player() -> void:
	if player != null and wake_spot != null:
		player.global_position = wake_spot.global_position


func _on_time_changed(minutes: int) -> void:
	if minutes == MIDNIGHT_MINUTES and notice != null:
		notice.show_message(LATE_MESSAGE)
