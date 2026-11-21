extends GameTestSuite
## Tests for ActionPrompt: the corner lines saying what Interact and Use tool
## would do, and naming the buttons for the device last used.

const COUNTER_SCENE: String = "res://scenes/prototype/props/counter.tscn"
const BOARD: Item = preload("res://data/items/chopping_board.tres")
const LETTUCE: Item = preload("res://data/items/lettuce.tres")
## A counter 1.2 m ahead of the player (who faces -Z), within reach.
const AHEAD: Vector3 = Vector3(0, 0, -1.2)


func test_both_lines_hide_with_nothing_in_reach() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var prompt: ActionPrompt = _prompt(new_hud_3d(player))
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 5)

	assert_bool(_line(prompt, "InteractLine").visible).is_false()
	assert_bool(_line(prompt, "ToolLine").visible).is_false()


func test_says_what_interact_and_the_knife_would_do() -> void:
	var player: Player3D = new_player_3d_on_floor()
	_add_board(player)
	var prompt: ActionPrompt = _prompt(new_hud_3d(player))
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	player.arms.add(ItemInstance.new(LETTUCE))
	await physics_ticks(runner, 5)

	assert_str(_line(prompt, "InteractLine").text) \
			.is_equal("[E] Put Lettuce on Chopping Board")
	assert_bool(_line(prompt, "ToolLine").visible).is_false()

	await press(runner, "interact")
	await physics_ticks(runner, 2)

	assert_str(_line(prompt, "InteractLine").text).is_equal("[E] Take Lettuce")
	assert_str(_line(prompt, "ToolLine").text).is_equal("[F] Chop")


func test_names_controller_buttons_after_a_controller_press() -> void:
	var player: Player3D = new_player_3d_on_floor()
	_add_board(player)
	var prompt: ActionPrompt = _prompt(new_hud_3d(player))
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 5)

	# Y isn't bound to anything in the galley, so the press changes nothing else.
	var pad_press: InputEventJoypadButton = InputEventJoypadButton.new()
	pad_press.button_index = JOY_BUTTON_Y
	pad_press.pressed = true
	prompt._input(pad_press)
	await physics_ticks(runner, 2)

	assert_bool(prompt.using_pad).is_true()
	assert_str(_line(prompt, "InteractLine").text).is_equal("[X] Pick up Chopping Board")

	var key: InputEventKey = InputEventKey.new()
	key.physical_keycode = KEY_W
	key.pressed = true
	prompt._input(key)
	await physics_ticks(runner, 2)

	assert_bool(prompt.using_pad).is_false()
	assert_str(_line(prompt, "InteractLine").text).is_equal("[E] Pick up Chopping Board")


func test_a_drifting_stick_keeps_the_keyboard_names() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var prompt: ActionPrompt = _prompt(new_hud_3d(player))
	scene_runner(player.get_parent())
	var drift: InputEventJoypadMotion = InputEventJoypadMotion.new()
	drift.axis = JOY_AXIS_LEFT_X
	drift.axis_value = 0.2

	prompt._input(drift)
	assert_bool(prompt.using_pad).is_false()

	drift.axis_value = -0.8
	prompt._input(drift)
	assert_bool(prompt.using_pad).is_true()


func test_button_names_come_from_the_input_map() -> void:
	assert_str(ActionPrompt.button_name(&"interact", false)).is_equal("E")
	assert_str(ActionPrompt.button_name(&"interact", true)).is_equal("X")
	assert_str(ActionPrompt.button_name(&"use_tool", false)).is_equal("F")
	assert_str(ActionPrompt.button_name(&"use_tool", true)).is_equal("B")
	assert_str(ActionPrompt.button_name(&"no_such_action", false)).is_equal("?")


func test_xbox_button_names() -> void:
	assert_str(ActionPrompt.pad_button_name(JOY_BUTTON_A)).is_equal("A")
	assert_str(ActionPrompt.pad_button_name(JOY_BUTTON_Y)).is_equal("Y")
	assert_str(ActionPrompt.pad_button_name(JOY_BUTTON_RIGHT_SHOULDER)).is_equal("RB")
	assert_str(ActionPrompt.pad_button_name(JOY_BUTTON_DPAD_UP)).is_equal("D-pad Up")
	assert_str(ActionPrompt.pad_button_name(JOY_BUTTON_PADDLE1)).is_equal("Button 16")


func _add_board(player: Player3D) -> Counter3D:
	var counter: Counter3D = (load(COUNTER_SCENE) as PackedScene).instantiate() as Counter3D
	counter.start_item = BOARD
	counter.position = AHEAD
	player.get_parent().add_child(counter)
	return counter


func _prompt(hud: Hud3D) -> ActionPrompt:
	return hud.find_child("ActionPrompt") as ActionPrompt


# A prompt line, freshly updated: the prompt updates on rendered frames, and
# the tests wait on physics ticks.
func _line(prompt: ActionPrompt, line_name: String) -> Label:
	prompt.refresh()
	return prompt.get_node(line_name) as Label
