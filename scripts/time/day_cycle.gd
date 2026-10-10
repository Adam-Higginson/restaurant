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
	# TODO 1: if it's already night, return. Otherwise set _is_night.
	# TODO 2: dismiss the notice (it's optional, so check it isn't null), then
	#         pause the game: get_tree().paused = true
	# TODO 3: the night, one awaited step at a time:
	#         - await the screen fading out
	#         - start the next day on game_state, then _wake_player()
	#         - await the title showing Calendar.format_date(game_state.day)
	#         - hold it: await get_tree().create_timer(title_seconds).timeout
	#           (scene-tree timers keep counting while the game is paused)
	#         - await the screen fading back in
	# TODO 4: unpause, clear _is_night, and emit morning_started.
	pass


func _wake_player() -> void:
	# TODO 5: if there's a player and a wake spot, move the player's
	#         global_position to the wake spot's global_position.
	pass


func _on_time_changed(minutes: int) -> void:
	# TODO 6: at exactly MIDNIGHT_MINUTES, show LATE_MESSAGE on the notice (if
	#         there is one). The clock only moves forward and resets each
	#         morning, so == fires once a night.
	pass
