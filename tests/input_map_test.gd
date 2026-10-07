extends GameTestSuite
## Checks that every row of the GDD's Controls table works from both the
## keyboard and a controller, so core play never depends on one of them.

const ACTIONS: Array[StringName] = [
	&"move_up", &"move_down", &"move_left", &"move_right",
	&"interact", &"pick_up", &"use_tool", &"rotate_stack",
]


func test_every_action_has_keyboard_and_controller_bindings() -> void:
	for action: StringName in ACTIONS:
		assert_bool(InputMap.has_action(action)).override_failure_message(
			"Missing input action: %s" % action
		).is_true()
		var has_key: bool = false
		var has_joypad: bool = false
		for event: InputEvent in InputMap.action_get_events(action):
			has_key = has_key or event is InputEventKey
			has_joypad = has_joypad or event is InputEventJoypadButton \
					or event is InputEventJoypadMotion
		assert_bool(has_key).override_failure_message(
			"%s has no keyboard binding" % action
		).is_true()
		assert_bool(has_joypad).override_failure_message(
			"%s has no controller binding" % action
		).is_true()


func test_belt_slots_are_selectable_from_keyboard_and_controller() -> void:
	# No single action has both: the keyboard picks slots 1 to 4 directly, and
	# the controller cycles with the left bumper. The scroll wheel goes both ways.
	for i: int in ToolBelt.SLOT_COUNT:
		var action: StringName = StringName("select_slot_%d" % (i + 1))
		assert_bool(_has_event(action, "InputEventKey")).override_failure_message(
			"%s has no keyboard binding" % action
		).is_true()
	assert_bool(_has_event(&"select_slot_next", "InputEventJoypadButton")).is_true()
	assert_bool(_has_event(&"select_slot_next", "InputEventMouseButton")).is_true()
	assert_bool(_has_event(&"select_slot_previous", "InputEventMouseButton")).is_true()


func _has_event(action: StringName, event_class: String) -> bool:
	if not InputMap.has_action(action):
		return false
	for event: InputEvent in InputMap.action_get_events(action):
		if event.is_class(event_class):
			return true
	return false
