class_name WaitCues
extends CueHandler
## Pauses in a cutscene. [code]@wait 1.5[/code] holds the script for that
## many seconds. [code]@wait_for interact[/code] holds it until the player
## presses Interact, however long that takes: the scene waits for them.
## [code]@wait_for any[/code] waits for any key or button at all (a title
## screen). Words after either are shown as a prompt while it waits:
## [code]@wait_for interact Take his hand[/code]. While it waits for any
## button, the [BuildTag] shows which build this is in the corner.
##
## Skipping a cutscene passes straight through all of them.

## Where a wait's prompt is shown. Optional: without one it waits silently.
@export var prompt: CutscenePrompt
## Which build this is, shown in the corner while the script waits for any
## button: on the title. Optional.
@export var build_tag: BuildTag

## What the script is waiting for now: "interact", "any", or "" for nothing.
var _waiting_for: String = ""
## Whether it's been pressed since the script started waiting for it.
var _pressed: bool = false


func cues() -> Array[StringName]:
	return [&"wait", &"wait_for"]


func _input(event: InputEvent) -> void:
	if _waiting_for != "any" or not event.is_pressed() or event.is_echo():
		return
	if event is InputEventKey or event is InputEventJoypadButton \
			or event is InputEventMouseButton:
		_pressed = true
		get_viewport().set_input_as_handled()


func _perform(cue: StringName, args: PackedStringArray) -> void:
	var held: int = hold()
	if cue == &"wait":
		await pause(args[0].to_float(), held)
		release(held)
		return
	_pressed = false
	_waiting_for = args[0]
	var words: String = " ".join(args.slice(1))
	if is_instance_valid(prompt) and not words.is_empty() and is_holding(held):
		prompt.show_prompt(words, args[0] == "interact")
	var on_title: bool = args[0] == "any" and is_instance_valid(build_tag) and is_holding(held)
	if on_title:
		build_tag.show_tag()
	while not _pressed and is_holding(held) and is_inside_tree():
		await get_tree().physics_frame
	_waiting_for = ""
	if is_instance_valid(prompt):
		prompt.hide_prompt()
	if on_title and is_instance_valid(build_tag):
		build_tag.hide_tag()
	release(held)


func _on_pressed_while_held() -> void:
	if _waiting_for == "interact":
		_pressed = true
