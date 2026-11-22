extends GameTestSuite
## Tests for pauses in a cutscene: @wait holds the script for its seconds,
## @wait_for interact holds it until the button's pressed, skipping passes
## both, and a handler that's gone doesn't leave the script waiting for ever.

var _player: Player3D
var _conversation: Conversation
var _waits: WaitCues
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


# The player, a conversation and the wait cues. Called at the start of each
# test, so everything is made (and freed) inside it.
func _build() -> void:
	_lines = 0
	_player = new_player_3d_on_floor()
	_conversation = new_conversation(_player)
	_conversation.line_said.connect(func(_speaker: Person) -> void: _lines += 1)
	_waits = WaitCues.new()
	_player.get_parent().add_child(_waits)
