class_name WindowToggle
extends Node
## Switches the game between fullscreen and a window (#196): Alt+Enter or F11
## (the [code]toggle_fullscreen[/code] action). An autoload, so it works
## everywhere, in every scene.
##
## Builds start fullscreen (Godot's borderless "Fullscreen", which covers the
## screen like a window and alt-tabs at once: [code]window/size/mode.release[/code]
## in the project settings); run from the editor, the game starts in a window.

## The input action that switches.
const ACTION: StringName = &"toggle_fullscreen"


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(ACTION):
		DisplayServer.window_set_mode(next_mode(DisplayServer.window_get_mode()))
		get_viewport().set_input_as_handled()


## The mode to switch to from [param mode]: a window from any fullscreen,
## fullscreen from any window.
static func next_mode(mode: DisplayServer.WindowMode) -> DisplayServer.WindowMode:
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN \
			or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		return DisplayServer.WINDOW_MODE_WINDOWED
	return DisplayServer.WINDOW_MODE_FULLSCREEN
