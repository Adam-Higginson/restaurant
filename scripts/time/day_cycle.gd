class_name DayCycle
extends Node
## Moves the game's clock on with real time, every frame. The clock and the
## game state handle the rest: pausing, and ending the day at 2:00 am.
##
## Next (#11, part 2): the fade to sleep, waking by the bed, the morning title
## card and the midnight nudge.

## The state whose clock this runs. Tests set their own before adding it;
## otherwise it's the [code]Game[/code] autoload.
var game_state: GameState = null


func _ready() -> void:
	if game_state == null:
		game_state = Game


func _process(delta: float) -> void:
	game_state.clock.tick(delta)
