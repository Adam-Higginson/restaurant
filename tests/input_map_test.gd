extends GameTestSuite
## Checks that every action in the GDD's Controls table is bound to both the
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
