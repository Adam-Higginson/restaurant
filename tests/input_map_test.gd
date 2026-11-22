extends GameTestSuite
## Checks that every row of the GDD's Controls table works from both the
## keyboard and a controller, so core play never depends on one of them.

const ACTIONS: Array[StringName] = [
	&"move_up", &"move_down", &"move_left", &"move_right",
	&"interact", &"use_tool", &"lock_on", &"parry",
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


func test_one_button_does_everything() -> void:
	# E and Space, and X and A on a controller, are the same action. See
	# Controls in docs/GDD.md.
	assert_bool(InputMap.has_action(&"pick_up")).is_false()
	var keys: Array[Key] = []
	var buttons: Array[JoyButton] = []
	for event: InputEvent in InputMap.action_get_events(&"interact"):
		if event is InputEventKey:
			keys.append((event as InputEventKey).physical_keycode)
		elif event is InputEventJoypadButton:
			buttons.append((event as InputEventJoypadButton).button_index)
	assert_array(keys).contains_exactly_in_any_order([KEY_E, KEY_SPACE])
	assert_array(buttons).contains_exactly_in_any_order([JOY_BUTTON_X, JOY_BUTTON_A])


func test_toolbar_slots_are_selectable_from_keyboard_and_controller() -> void:
	# No single action has both: the keyboard picks slots 1 to 12 directly
	# (1-9, 0, - and =), and the controller cycles with the bumpers. The
	# scroll wheel zooms the camera instead.
	for i: int in Toolbar.SLOT_COUNT:
		var action: StringName = StringName("select_slot_%d" % (i + 1))
		assert_bool(_has_event(action, "InputEventKey")).override_failure_message(
			"%s has no keyboard binding" % action
		).is_true()
	for action: StringName in [&"select_slot_next", &"select_slot_previous"]:
		assert_bool(_has_event(action, "InputEventJoypadButton")).is_true()
		assert_bool(_has_event(action, "InputEventMouseButton")).is_false()


func test_the_scroll_wheel_zooms_the_camera() -> void:
	assert_array(_mouse_buttons(&"zoom_in")).contains_exactly([MOUSE_BUTTON_WHEEL_UP])
	assert_array(_mouse_buttons(&"zoom_out")).contains_exactly([MOUSE_BUTTON_WHEEL_DOWN])


func test_the_mouse_buttons_interact_and_use_tools() -> void:
	# Like Stardew Valley: right click does things, left click uses the tool.
	assert_array(_mouse_buttons(&"interact")).contains_exactly([MOUSE_BUTTON_RIGHT])
	assert_array(_mouse_buttons(&"use_tool")).contains_exactly([MOUSE_BUTTON_LEFT])


func test_lock_on_and_parry_are_on_the_triggers_shift_and_r() -> void:
	# Like OoT: target on the left trigger, shield on the right. See Controls
	# in docs/GDD.md.
	assert_array(_keys(&"lock_on")).contains_exactly([KEY_SHIFT])
	assert_array(_mouse_buttons(&"lock_on")).contains_exactly([MOUSE_BUTTON_MIDDLE])
	assert_array(_axes(&"lock_on")).contains_exactly([JOY_AXIS_TRIGGER_LEFT])
	assert_array(_keys(&"parry")).contains_exactly([KEY_R])
	assert_array(_axes(&"parry")).contains_exactly([JOY_AXIS_TRIGGER_RIGHT])


func test_debug_keys_are_on_the_keyboard() -> void:
	# Testing shortcuts (DebugKeys), not part of play, so keyboard only.
	for action: StringName in [&"debug_skip_hour", &"debug_fast_forward", &"debug_spawn_customer"]:
		assert_bool(_has_event(action, "InputEventKey")).override_failure_message(
			"%s has no keyboard binding" % action
		).is_true()


func test_the_camera_turns_with_the_right_stick() -> void:
	# On keyboard and mouse the camera follows the mouse, which CameraRig
	# reads directly: mouse movement can't be bound to an action.
	var axes: Dictionary[StringName, Vector2] = {
		&"camera_left": Vector2(JOY_AXIS_RIGHT_X, -1.0),
		&"camera_right": Vector2(JOY_AXIS_RIGHT_X, 1.0),
		&"camera_up": Vector2(JOY_AXIS_RIGHT_Y, -1.0),
		&"camera_down": Vector2(JOY_AXIS_RIGHT_Y, 1.0),
	}
	for action: StringName in axes:
		var bound: Array[Vector2] = []
		if InputMap.has_action(action):
			for event: InputEvent in InputMap.action_get_events(action):
				var motion: InputEventJoypadMotion = event as InputEventJoypadMotion
				if motion != null:
					bound.append(Vector2(motion.axis, motion.axis_value))
		assert_array(bound).override_failure_message(
			"%s isn't bound to the right stick" % action
		).contains([axes[action]])


func _mouse_buttons(action: StringName) -> Array[MouseButton]:
	var buttons: Array[MouseButton] = []
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventMouseButton:
			buttons.append((event as InputEventMouseButton).button_index)
	return buttons


func _keys(action: StringName) -> Array[Key]:
	var keys: Array[Key] = []
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey:
			keys.append((event as InputEventKey).physical_keycode)
	return keys


func _axes(action: StringName) -> Array[JoyAxis]:
	var axes: Array[JoyAxis] = []
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventJoypadMotion:
			axes.append((event as InputEventJoypadMotion).axis)
	return axes


func _has_event(action: StringName, event_class: String) -> bool:
	if not InputMap.has_action(action):
		return false
	for event: InputEvent in InputMap.action_get_events(action):
		if event.is_class(event_class):
			return true
	return false
