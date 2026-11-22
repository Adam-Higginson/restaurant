extends GameTestSuite
## Tests for ParryWindow: how long the pan is up, and how soon it can go up
## again.


func test_the_pan_is_down_until_pressed() -> void:
	var parry: ParryWindow = ParryWindow.new()

	assert_bool(parry.is_active()).is_false()


func test_a_press_opens_the_window() -> void:
	var parry: ParryWindow = ParryWindow.new()

	assert_bool(parry.press()).is_true()

	assert_bool(parry.is_active()).is_true()


func test_the_window_lasts_its_time_and_no_longer() -> void:
	var parry: ParryWindow = ParryWindow.new()
	parry.press()

	parry.tick(parry.window_seconds - 0.01)
	assert_bool(parry.is_active()).is_true()
	parry.tick(0.02)

	assert_bool(parry.is_active()).is_false()


func test_mashing_the_button_doesnt_keep_the_pan_up() -> void:
	var parry: ParryWindow = ParryWindow.new()
	parry.press()
	parry.tick(parry.window_seconds + 0.01)

	# Still recovering: this press is ignored.
	assert_bool(parry.press()).is_false()
	assert_bool(parry.is_active()).is_false()


func test_it_can_be_raised_again_after_recovering() -> void:
	var parry: ParryWindow = ParryWindow.new()
	parry.press()
	parry.tick(parry.window_seconds + parry.recovery_seconds + 0.01)

	assert_bool(parry.press()).is_true()
	assert_bool(parry.is_active()).is_true()


func test_a_used_parry_closes_the_window_and_is_ready_again() -> void:
	var parry: ParryWindow = ParryWindow.new()
	parry.press()

	parry.spend()

	assert_bool(parry.is_active()).is_false()
	assert_bool(parry.press()).is_true()
