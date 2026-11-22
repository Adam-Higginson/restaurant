extends GameTestSuite
## Tests for pauses in a cutscene: @wait holds the script for its seconds,
## @wait_for interact holds it until the button's pressed, skipping passes
## both, and a handler that's gone doesn't leave the script waiting for ever.

var _player: Player3D
var _conversation: Conversation
var _waits: WaitCues
var _prompt: CutscenePrompt
## How many lines have been said.
var _lines: int


func before_test() -> void:
	Game.dialogue.reset()


func after_test() -> void:
	Game.dialogue.reset()


func test_wait_holds_the_script_for_its_seconds() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)

	play_cutscene(_conversation, _player, "@wait 0.5\nheron: After.")
	await physics_ticks(runner, 20)
	assert_int(_lines).is_equal(0)

	await physics_ticks(runner, 15)
	assert_int(_lines).is_equal(1)


func test_pressing_interact_doesnt_cut_a_wait_short() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	play_cutscene(_conversation, _player, "@wait 1.0\nheron: After.")

	await press(runner, "interact")
	await press(runner, "interact")

	assert_int(_lines).is_equal(0)
	assert_bool(_conversation.is_active()).is_true()


func test_wait_for_interact_holds_until_the_press() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	play_cutscene(_conversation, _player, "@wait_for interact\nheron: After.")

	await physics_ticks(runner, 90)
	assert_int(_lines).is_equal(0)

	await press(runner, "interact")
	assert_int(_lines).is_equal(1)


func test_a_press_before_the_wait_doesnt_count() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	play_cutscene(_conversation, _player,
			"@wait_for interact\n@wait_for interact\nheron: After.")

	await press(runner, "interact")
	assert_int(_lines).is_equal(0)

	await press(runner, "interact")
	assert_int(_lines).is_equal(1)


func test_skipping_passes_straight_through_both() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	play_cutscene(_conversation, _player, "@wait 30\n@wait_for interact\nset done")
	await physics_ticks(runner, 5)

	_conversation.skip()

	assert_bool(_conversation.is_active()).is_false()
	assert_bool(Game.dialogue.is_set(&"done")).is_true()


func test_a_wait_during_a_skip_holds_nothing() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	play_cutscene(_conversation, _player, "heron: One.\n@wait 30\n@wait 30\nset done")

	_conversation.skip()
	await physics_ticks(runner, 3)

	assert_bool(_conversation.is_active()).is_false()
	assert_bool(Game.dialogue.is_set(&"done")).is_true()


func test_a_handler_thats_gone_doesnt_leave_the_script_waiting() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	play_cutscene(_conversation, _player, "@wait 30\nheron: After.")
	await physics_ticks(runner, 5)

	_waits.queue_free()
	await physics_ticks(runner, 5)

	assert_int(_lines).is_equal(1)


func test_a_wait_left_over_from_a_stopped_cutscene_doesnt_release_the_next() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	play_cutscene(_conversation, _player, "@wait 0.2\nheron: First.")
	await physics_ticks(runner, 3)

	_conversation.stop()
	play_cutscene(_conversation, _player, "@wait 1.0\nheron: Second.")
	# Long enough for the first wait to have ended, not the second.
	await physics_ticks(runner, 30)

	assert_int(_lines).is_equal(0)
	assert_bool(_conversation.is_active()).is_true()


func test_wait_for_any_holds_until_any_key_at_all() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	play_cutscene(_conversation, _player, "@wait_for any\nheron: After.")

	await physics_ticks(runner, 90)
	assert_int(_lines).is_equal(0)

	runner.simulate_key_pressed(KEY_K)
	await physics_ticks(runner, 3)
	assert_int(_lines).is_equal(1)


func test_any_button_doesnt_end_a_wait_for_interact() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	play_cutscene(_conversation, _player, "@wait_for interact\nheron: After.")

	runner.simulate_key_pressed(KEY_K)
	await physics_ticks(runner, 3)

	assert_int(_lines).is_equal(0)


func test_words_after_a_wait_are_shown_as_a_prompt_until_the_press() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)

	play_cutscene(_conversation, _player, "@wait_for any Press any button\nheron: After.")
	await physics_ticks(runner, 3)
	assert_bool(_prompt.is_prompting).is_true()
	assert_str(_prompt.shown_text()).is_equal("Press any button")

	runner.simulate_key_pressed(KEY_K)
	await physics_ticks(runner, 3)
	assert_bool(_prompt.is_prompting).is_false()
	assert_str(_prompt.shown_text()).is_empty()


func test_a_prompt_for_interact_names_its_button() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)

	play_cutscene(_conversation, _player, "@wait_for interact Take his hand\nheron: After.")
	await physics_ticks(runner, 3)

	assert_str(_prompt.shown_text()).ends_with("] Take his hand").starts_with("[")


func test_a_wait_with_no_words_shows_no_prompt() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)

	play_cutscene(_conversation, _player, "@wait_for interact\nheron: After.")
	await physics_ticks(runner, 3)

	assert_bool(_prompt.is_prompting).is_false()


func test_skipping_takes_the_prompt_away() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	play_cutscene(_conversation, _player, "@wait_for any Press any button\nset done")
	await physics_ticks(runner, 3)

	_conversation.skip()
	await physics_ticks(runner, 3)

	assert_bool(_prompt.is_prompting).is_false()
	assert_bool(Game.dialogue.is_set(&"done")).is_true()


# The player, a conversation, the wait cues and their prompt. Called at the
# start of each test, so everything is made (and freed) inside it.
func _build() -> void:
	_lines = 0
	_player = new_player_3d_on_floor()
	_conversation = new_conversation(_player)
	_conversation.line_said.connect(func(_speaker: Person) -> void: _lines += 1)
	_prompt = (load("res://ui/cutscene_prompt.tscn") as PackedScene).instantiate() \
			as CutscenePrompt
	_player.get_parent().add_child(_prompt)
	_waits = WaitCues.new()
	_waits.prompt = _prompt
	_player.get_parent().add_child(_waits)
