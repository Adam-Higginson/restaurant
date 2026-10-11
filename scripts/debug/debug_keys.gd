class_name DebugKeys
extends Node
## Shortcuts for testing by hand, so you don't wait hours of game time for
## lunch. They only work in debug builds (running from the editor), never in
## an exported game.
##
## F9 skips an hour, F10 switches fast forward on and off, F11 brings a
## customer in now.

## How much faster the clock runs while fast forward is on.
const FAST_FORWARD_FACTOR: float = 20.0
## Clock steps in an hour (10 minutes each).
const STEPS_PER_HOUR: int = 6

## Brings customers in on F11. Optional.
@export var spawner: CustomerSpawner = null

## The state whose clock it moves. Tests set their own before adding it;
## otherwise it's the [code]Game[/code] autoload.
var game_state: GameState = null


func _ready() -> void:
	if game_state == null:
		game_state = Game
	set_process_unhandled_input(OS.is_debug_build())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"debug_skip_hour"):
		skip_hour()
	elif event.is_action_pressed(&"debug_fast_forward"):
		toggle_fast_forward()
	elif event.is_action_pressed(&"debug_spawn_customer"):
		spawn_customer()
	else:
		return
	get_viewport().set_input_as_handled()


## Moves the clock on an hour, step by step, so everything that listens to
## the clock (arrivals, the midnight note, the light) happens on the way.
## Does nothing while the clock is paused.
func skip_hour() -> void:
	var clock: GameClock = game_state.clock
	clock.tick(clock.seconds_per_step * STEPS_PER_HOUR)


## Runs the clock [constant FAST_FORWARD_FACTOR] times faster, or back at
## normal speed if it already is.
func toggle_fast_forward() -> void:
	var clock: GameClock = game_state.clock
	if is_fast_forward():
		clock.seconds_per_step = GameClock.DEFAULT_SECONDS_PER_STEP
	else:
		clock.seconds_per_step = GameClock.DEFAULT_SECONDS_PER_STEP / FAST_FORWARD_FACTOR


func is_fast_forward() -> bool:
	return game_state.clock.seconds_per_step < GameClock.DEFAULT_SECONDS_PER_STEP


## Brings a customer in now, whatever the time or the sign says.
func spawn_customer() -> void:
	if spawner != null:
		spawner.spawn_customer()
