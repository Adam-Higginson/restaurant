class_name ChoiceCues
extends CueHandler
## Asks the player something in a cutscene, and waits for the answer.
## [code]@who_are_you[/code] shows the "Who are you?" screen
## ([member choice], a [LookChoice]) over the scene, holds the script until
## a boy or a girl is picked, and puts the answer into the game
## ([method GameState.set_look]). The intro asks it on a new voyage, after
## the title.
##
## Skipping the cutscene still asks: who you are isn't skipped.

## The "Who are you?" screen. Set in the scene.
@export var choice: LookChoice
## Whether to ask at all. Off, you're whoever the game already says; tests
## of the rest of the intro turn it off.
@export var ask: bool = true


func cues() -> Array[StringName]:
	return [&"who_are_you"]


func _perform(_cue: StringName, _args: PackedStringArray) -> void:
	if not ask or choice == null:
		return
	var held: int = hold()
	choice.ask()
	var body: PlayerLook.Body = await choice.chosen
	Game.set_look(body)
	release(held)
