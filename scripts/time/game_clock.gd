class_name GameClock
extends RefCounted
## The time of day, from 6:00 am to 2:00 am, in 10-minute steps.
##
## Time is stored as minutes since the midnight the day started on, so
## 1:30 am the next morning is 25 * 60 + 30 = 1530. Something with a
## [code]_process[/code] (the day cycle) feeds it real time through
## [method tick]. It never ends the day itself: it emits [signal reached_end]
## and the game decides what happens.
##
## Panels pause it while they're open. Each one pauses as its own
## [i]source[/i], so closing one panel can't unpause the clock while another
## is still open.

## Emitted after each 10-minute step, with the new time.
signal time_changed(minutes: int)
## Emitted once when the clock reaches 2:00 am.
signal reached_end

## 6:00 am.
const START_MINUTES: int = 6 * 60
## 2:00 am the next morning.
const END_MINUTES: int = 26 * 60
const MINUTES_PER_STEP: int = 10
const DEFAULT_SECONDS_PER_STEP: float = 10.0

## Real seconds per 10-minute step. Tests make it shorter.
var seconds_per_step: float = DEFAULT_SECONDS_PER_STEP
## The current time, in minutes since the midnight the day started on.
var minutes: int:
	get:
		return _minutes
	set(_value):
		push_error("GameClock: minutes is read-only, use tick() or reset()")

var _minutes: int = START_MINUTES
## Real seconds counted towards the next step.
var _seconds_into_step: float = 0.0
## Everything currently pausing the clock.
var _pause_sources: Array[Object] = []


## Turns [param time] (minutes since midnight) into 12-hour text:
## "6:00 am", "12:40 pm", "12:00 am" for midnight, "1:50 am" after it.
static func format_time(time: int) -> String:
	# TODO(you)
	return ""


## Adds [param delta] real seconds. Every [member seconds_per_step] seconds,
## moves on one step and emits [signal time_changed]. A big delta can move
## several steps at once, and leftover seconds count towards the next step.
## Does nothing while paused or once the clock has reached the end. Emits
## [signal reached_end] the moment it gets there.
func tick(delta: float) -> void:
	# TODO(you)
	pass


## Stops the clock on behalf of [param source], usually a panel passing
## [code]self[/code]. Pausing twice for the same source counts once.
func pause(source: Object) -> void:
	# TODO(you)
	pass


## Releases [param source]'s pause. The clock runs again once no source is
## pausing it. Resuming a source that isn't pausing does nothing.
func resume(source: Object) -> void:
	# TODO(you)
	pass


func is_paused() -> bool:
	# TODO(you)
	return false


func has_ended() -> bool:
	# TODO(you)
	return false


## Back to 6:00 am for a new day, emitting [signal time_changed]. Pauses are
## kept, as they belong to whatever is still open.
func reset() -> void:
	# TODO(you)
	pass
