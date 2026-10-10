class_name TimeLabel
extends Label
## A temporary readout of the date, time and open state, e.g.
## "Spring 3, Wednesday · 6:40 pm · Open". The HUD (#13) replaces it.
##
## Display only: it listens to the game state's signals and redraws its text
## when anything changes.

## The state shown. Tests set their own before adding the label; otherwise
## it's the [code]Game[/code] autoload.
var game_state: GameState = null


func _ready() -> void:
	if game_state == null:
		game_state = Game
	game_state.day_changed.connect(_update)
	game_state.open_changed.connect(_update)
	game_state.clock.time_changed.connect(_update)
	# Fill it in now rather than waiting for the first signal.
	_update()


## The text shown for [param day] at [param minutes], open or closed.
static func describe(day: int, minutes: int, is_open: bool) -> String:
	return "{date} · {time} · {open}".format({
		"date": Calendar.format_date(day),
		"time": GameClock.format_time(minutes),
		"open": "Open" if is_open else "Closed",
	})


# Takes and ignores each signal's value, so one function can listen to all of
# them.
func _update(_value: Variant = null) -> void:
	text = describe(game_state.day, game_state.clock.minutes, game_state.is_open)
