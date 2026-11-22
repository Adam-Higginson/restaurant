class_name WaitCues
extends CueHandler
## Pauses in a cutscene. [code]@wait 1.5[/code] holds the script for that
## many seconds. [code]@wait_for interact[/code] holds it until the player
## presses Interact, however long that takes: the scene waits for them.
##
## Skipping a cutscene passes straight through both.

## Whether Interact has been pressed since the script started waiting for it.
var _pressed: bool = false


func cues() -> Array[StringName]:
	return [&"wait", &"wait_for"]


func _perform(cue: StringName, args: PackedStringArray) -> void:
	var held: int = hold()
	if cue == &"wait":
		await pause(args[0].to_float(), held)
	else:
		_pressed = false
		while not _pressed and is_holding(held) and is_inside_tree():
			await get_tree().physics_frame
	release(held)


func _on_pressed_while_held() -> void:
	_pressed = true
