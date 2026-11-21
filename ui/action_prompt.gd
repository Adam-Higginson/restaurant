class_name ActionPrompt
extends VBoxContainer
## The corner prompt saying what Interact and Use tool would do right now,
## like OoT's A-button text: "[E] Put down Tomato" above "[F] Chop". Each line
## hides when its button would do nothing.
##
## Button names follow the last device used: keys after a key press, mouse
## buttons after a click ("[RMB] Put down Tomato", "[LMB] Chop"), and Xbox
## buttons after a controller press.
##
## Display only: the words come from the player's [InteractionDetector3D],
## which asks the focused prop. [Hud3D] hands it the player.

## Whose button names to show.
enum Device { KEYBOARD, MOUSE, PAD }

## How far a stick must move to count as using the controller, so a resting
## stick's drift doesn't switch the names.
const STICK_THRESHOLD: float = 0.5

## Whose button names are shown: the last device used.
var device: Device:
	get:
		return _device

var _device: Device = Device.KEYBOARD
var _detector: InteractionDetector3D = null

@onready var _interact_line: Label = $InteractLine
@onready var _tool_line: Label = $ToolLine


func _ready() -> void:
	_show_lines("", "")


# Every frame, because what the buttons would do depends on what's in front of
# the player as well as what they hold, and both change as they walk.
func _process(_delta: float) -> void:
	refresh()


# _input rather than _unhandled_input: it sees every press first, even ones
# the game then handles, and never marks them handled.
func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		_device = Device.KEYBOARD
	elif event is InputEventMouseButton:
		_device = Device.MOUSE
	elif event is InputEventJoypadButton:
		_device = Device.PAD
	elif event is InputEventJoypadMotion \
			and absf((event as InputEventJoypadMotion).axis_value) > STICK_THRESHOLD:
		_device = Device.PAD


## Starts prompting for [param player].
func setup(player: Player3D) -> void:
	_detector = player.get_node("InteractionDetector") as InteractionDetector3D


## Re-reads what the buttons would do and updates the lines. Runs every
## frame; tests call it to check the lines without waiting for one.
func refresh() -> void:
	if _detector == null:
		return
	_show_lines(_detector.interact_prompt(), _detector.tool_prompt())


## The text of a prompt line: [param action]'s button, then [param text].
func line_text(action: StringName, text: String) -> String:
	return "[%s] %s" % [button_name(action, _device), text]


## The name of the first button of device [param on] bound to [param action]:
## a key like "E", a mouse button like "RMB", or an Xbox button like "X". With
## the mouse it falls back to the key if the action has no mouse button. "?"
## if nothing fits.
static func button_name(action: StringName, on: Device) -> String:
	var key_name: String = "?"
	for event: InputEvent in InputMap.action_get_events(action):
		if on == Device.PAD and event is InputEventJoypadButton:
			return pad_button_name((event as InputEventJoypadButton).button_index)
		if on == Device.MOUSE and event is InputEventMouseButton:
			return mouse_button_name((event as InputEventMouseButton).button_index)
		if event is InputEventKey and key_name == "?":
			key_name = OS.get_keycode_string((event as InputEventKey).physical_keycode)
	return "?" if on == Device.PAD else key_name


## A short name for a mouse button.
static func mouse_button_name(index: MouseButton) -> String:
	match index:
		MOUSE_BUTTON_LEFT:
			return "LMB"
		MOUSE_BUTTON_RIGHT:
			return "RMB"
		MOUSE_BUTTON_MIDDLE:
			return "MMB"
	return "Mouse %d" % index


## The Xbox name of a controller button, as Godot numbers them (Godot uses
## Xbox's layout, so A is 0 and B is 1).
static func pad_button_name(index: JoyButton) -> String:
	match index:
		JOY_BUTTON_A:
			return "A"
		JOY_BUTTON_B:
			return "B"
		JOY_BUTTON_X:
			return "X"
		JOY_BUTTON_Y:
			return "Y"
		JOY_BUTTON_LEFT_SHOULDER:
			return "LB"
		JOY_BUTTON_RIGHT_SHOULDER:
			return "RB"
		JOY_BUTTON_BACK:
			return "View"
		JOY_BUTTON_START:
			return "Menu"
		JOY_BUTTON_LEFT_STICK:
			return "LS"
		JOY_BUTTON_RIGHT_STICK:
			return "RS"
		JOY_BUTTON_DPAD_UP:
			return "D-pad Up"
		JOY_BUTTON_DPAD_DOWN:
			return "D-pad Down"
		JOY_BUTTON_DPAD_LEFT:
			return "D-pad Left"
		JOY_BUTTON_DPAD_RIGHT:
			return "D-pad Right"
	return "Button %d" % index


func _show_lines(interact_text: String, tool_text: String) -> void:
	_interact_line.visible = not interact_text.is_empty()
	_interact_line.text = line_text(&"interact", interact_text) if _interact_line.visible else ""
	_tool_line.visible = not tool_text.is_empty()
	_tool_line.text = line_text(&"use_tool", tool_text) if _tool_line.visible else ""
