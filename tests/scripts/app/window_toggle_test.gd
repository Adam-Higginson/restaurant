extends GameTestSuite
## Tests for switching between fullscreen and a window (#196): which way it
## switches, its keys, and builds starting fullscreen.


func test_a_window_goes_fullscreen_and_fullscreen_goes_back_to_a_window() -> void:
	assert_int(WindowToggle.next_mode(DisplayServer.WINDOW_MODE_WINDOWED)) \
			.is_equal(DisplayServer.WINDOW_MODE_FULLSCREEN)
	assert_int(WindowToggle.next_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)) \
			.is_equal(DisplayServer.WINDOW_MODE_FULLSCREEN)
	assert_int(WindowToggle.next_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)) \
			.is_equal(DisplayServer.WINDOW_MODE_WINDOWED)
	assert_int(WindowToggle.next_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)) \
			.is_equal(DisplayServer.WINDOW_MODE_WINDOWED)


func test_alt_enter_and_f11_switch() -> void:
	assert_bool(InputMap.has_action(&"toggle_fullscreen")).is_true()
	var f11: InputEventKey = InputEventKey.new()
	f11.physical_keycode = KEY_F11
	f11.pressed = true
	var alt_enter: InputEventKey = InputEventKey.new()
	alt_enter.physical_keycode = KEY_ENTER
	alt_enter.alt_pressed = true
	alt_enter.pressed = true
	var enter: InputEventKey = InputEventKey.new()
	enter.physical_keycode = KEY_ENTER
	enter.pressed = true
	assert_bool(InputMap.event_is_action(f11, &"toggle_fullscreen", true)).is_true()
	assert_bool(InputMap.event_is_action(alt_enter, &"toggle_fullscreen", true)).is_true()
	# Enter on its own isn't the switch.
	assert_bool(InputMap.event_is_action(enter, &"toggle_fullscreen", true)).is_false()


func test_builds_start_fullscreen_and_the_editor_in_a_window() -> void:
	assert_int(ProjectSettings.get_setting("display/window/size/mode.release", -1)) \
			.is_equal(DisplayServer.WINDOW_MODE_FULLSCREEN)
	assert_int(ProjectSettings.get_setting("display/window/size/mode", 0)) \
			.is_equal(DisplayServer.WINDOW_MODE_WINDOWED)
