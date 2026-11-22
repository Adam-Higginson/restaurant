class_name CutsceneKeys
extends Node
## A shortcut for tuning cutscenes by hand. It only works in debug builds
## (running from the editor), never in an exported game.
##
## F8 reads the last cutscene's (or conversation's) file again and replays
## it from the section it had reached. So: edit the .dlg file, save it,
## press F8 in the running game, and watch that beat again.

## The input action that replays.
const REPLAY_ACTION: StringName = &"debug_replay_cutscene"


func _ready() -> void:
	set_process_unhandled_input(OS.is_debug_build())


func _unhandled_input(event: InputEvent) -> void:
	if InputMap.has_action(REPLAY_ACTION) and event.is_action_pressed(REPLAY_ACTION):
		get_viewport().set_input_as_handled()
		replay()


## Replays the last cutscene or conversation (see [method Conversation.replay]).
## Returns whether anything started.
func replay() -> bool:
	var conversation: Conversation = Conversation.find(self)
	return conversation != null and conversation.replay()
