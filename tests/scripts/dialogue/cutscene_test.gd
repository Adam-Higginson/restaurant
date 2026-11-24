extends GameTestSuite
## Tests for a conversation played as a cutscene: it can start part-way in,
## a cue can hold it, it can be skipped (running to its end with its flags
## set, but never past a choice), and it can be replayed while tuning.

const SKIPPABLE: String = "heron: One.\nset first\n@wait 30\nheron: Two.\nset second"
const SECTIONS: String = "heron: Start.\n-> two\n~ two\nheron: Two.\nheron: Three.\n-> last\n" \
		+ "~ last\nheron: Last."

var _player: Player3D
var _conversation: Conversation
var _hud: Hud3D
## What's been said, in order.
var _said: PackedStringArray


func before_test() -> void:
	Game.dialogue.reset()


func after_test() -> void:
	Game.dialogue.reset()


func test_a_cutscene_stops_you_walking_and_an_ordinary_talk_isnt_one() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)

	play_cutscene(_conversation, _player, "heron: One.")
	assert_bool(_conversation.is_cutscene()).is_true()
	assert_bool(_player.controls_enabled).is_false()
	_conversation.stop()
	assert_bool(_conversation.is_cutscene()).is_false()
	assert_bool(_player.controls_enabled).is_true()

	_conversation.begin_tree(DialogueScript.parse("heron: One.", &"test"), _player)
	assert_bool(_conversation.is_cutscene()).is_false()


func test_the_hearts_step_aside_for_a_cutscene_but_not_for_a_talk() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	var hearts: Control = _hud.get_node("%HeartsBar") as Control
	assert_float(hearts.modulate.a).is_equal(1.0)

	play_cutscene(_conversation, _player, "heron: One.")
	assert_float(hearts.modulate.a).is_equal(0.0)
	_conversation.stop()
	assert_float(hearts.modulate.a).is_equal(1.0)

	# In an ordinary talk (mid-duel, say) you still see how you're doing.
	_conversation.begin_tree(DialogueScript.parse("heron: One.", &"test"), _player)
	assert_float(hearts.modulate.a).is_equal(1.0)


func test_it_can_start_at_a_later_section() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)

	play_cutscene(_conversation, _player, SECTIONS, &"last")

	assert_array(_said).contains_exactly(["Last."])
	assert_str(String(_conversation.section())).is_equal("last")


func test_a_section_that_isnt_there_starts_nothing() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	var tree: DialogueTree = DialogueScript.parse(SECTIONS, &"test")

	assert_bool(_conversation.play_tree(tree, _player, &"nowhere")).is_false()

	assert_bool(_conversation.is_active()).is_false()
	assert_bool(_player.controls_enabled).is_true()


func test_a_cue_can_hold_the_script_and_the_box_steps_aside() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	var box: DialogueBox = _hud.get_node("%DialogueBox") as DialogueBox
	var holds: Array[int] = []
	_conversation.cue.connect(func(_name: StringName, _args: PackedStringArray) -> void:
		holds.append(_conversation.hold(self)))
	play_cutscene(_conversation, _player, "heron: One.\n@wait 5\nheron: Two.")
	await physics_ticks(runner, 2)
	assert_bool(box.visible).is_true()

	box.finish_typing()
	_conversation.press()
	assert_bool(_conversation.is_holding(holds[0])).is_true()
	assert_bool(box.visible).is_false()
	assert_array(_said).contains_exactly(["One."])

	_conversation.release(holds[0])
	assert_bool(_conversation.is_holding(holds[0])).is_false()
	assert_array(_said).contains_exactly(["One.", "Two."])


func test_a_press_while_held_is_passed_on_instead_of_moving_on() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	var presses: Array[int] = []
	_conversation.pressed_while_held.connect(func() -> void: presses.append(1))
	_conversation.cue.connect(func(_name: StringName, _args: PackedStringArray) -> void:
		_conversation.hold(self))
	play_cutscene(_conversation, _player, "@wait 5\nheron: After.")

	_conversation.press()

	assert_int(presses.size()).is_equal(1)
	assert_array(_said).is_empty()


func test_a_hold_from_a_stopped_cutscene_cant_release_the_next_one() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	var holds: Array[int] = []
	_conversation.cue.connect(func(_name: StringName, _args: PackedStringArray) -> void:
		holds.append(_conversation.hold(self)))
	play_cutscene(_conversation, _player, "@wait 5\nheron: First.")
	_conversation.stop()
	play_cutscene(_conversation, _player, "@wait 5\nheron: Second.")

	_conversation.release(holds[0])
	assert_array(_said).is_empty()

	_conversation.release(holds[1])
	assert_array(_said).contains_exactly(["Second."])


func test_skipping_runs_to_the_end_with_its_flags_set() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	_player.get_parent().add_child(WaitCues.new())
	await physics_ticks(runner, 2)
	play_cutscene(_conversation, _player, SKIPPABLE)

	_conversation.skip()

	assert_bool(_conversation.is_active()).is_false()
	assert_bool(_conversation.is_skipping()).is_false()
	assert_bool(Game.dialogue.is_set(&"first")).is_true()
	assert_bool(Game.dialogue.is_set(&"second")).is_true()
	assert_bool(_player.controls_enabled).is_true()
	# Nobody was reading: the skipped lines aren't shown or sounded.
	assert_array(_said).contains_exactly(["One."])


func test_skipping_stops_at_a_choice_which_is_yours_to_make() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	var ended: Array[int] = []
	_conversation.skip_ended.connect(func() -> void: ended.append(1))
	play_cutscene(_conversation, _player,
			"heron: One.\nheron: Two.\n- Yes. -> yes\n- No. -> END\n~ yes\nset agreed")

	_conversation.skip()

	assert_bool(_conversation.is_active()).is_true()
	assert_bool(_conversation.is_skipping()).is_false()
	assert_int(ended.size()).is_equal(1)
	assert_bool(Game.dialogue.is_set(&"agreed")).is_false()

	_press()
	assert_bool(Game.dialogue.is_set(&"agreed")).is_true()


func test_skipping_goes_past_a_choice_with_only_one_answer() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	play_cutscene(_conversation, _player,
			"heron: One.\n- (Nod) -> nod\n~ nod\nset nodded\nheron: Two.\nset done")

	_conversation.skip()

	# One answer is no choice: it's made for you, and it runs to the end.
	assert_bool(Game.dialogue.is_set(&"nodded")).is_true()
	assert_bool(Game.dialogue.is_set(&"done")).is_true()
	assert_bool(_conversation.is_active()).is_false()


func test_an_ordinary_talk_cant_be_skipped() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	_conversation.begin_tree(DialogueScript.parse("heron: One.\nheron: Two.", &"test"), _player)

	_conversation.skip()

	assert_bool(_conversation.is_active()).is_true()
	assert_bool(_conversation.is_skipping()).is_false()
	assert_array(_said).contains_exactly(["One."])


func test_holding_the_skip_button_for_a_second_skips() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	play_cutscene(_conversation, _player, "heron: One.\nheron: Two.\nset done")

	runner.simulate_action_press(String(Conversation.SKIP_ACTION))
	await physics_ticks(runner, 30)
	assert_bool(_conversation.is_active()).is_true()
	assert_float(_conversation.skip_progress()).is_between(0.3, 0.7)

	await physics_ticks(runner, 40)
	runner.simulate_action_release(String(Conversation.SKIP_ACTION))
	await physics_ticks(runner, 2)

	assert_bool(_conversation.is_active()).is_false()
	assert_bool(Game.dialogue.is_set(&"done")).is_true()


func test_letting_go_of_the_skip_button_early_starts_the_count_again() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	play_cutscene(_conversation, _player, "heron: One.\nheron: Two.")

	for i: int in 3:
		runner.simulate_action_press(String(Conversation.SKIP_ACTION))
		await physics_ticks(runner, 40)
		runner.simulate_action_release(String(Conversation.SKIP_ACTION))
		await physics_ticks(runner, 3)

	assert_bool(_conversation.is_active()).is_true()
	assert_float(_conversation.skip_progress()).is_equal(0.0)


func test_replay_starts_again_from_the_section_it_had_reached() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	play_cutscene(_conversation, _player, SECTIONS)
	_press()
	_press()
	assert_array(_said).contains_exactly(["Start.", "Two.", "Three."])
	_said.clear()

	assert_bool(_conversation.replay()).is_true()

	assert_array(_said).contains_exactly(["Two."])
	assert_bool(_conversation.is_cutscene()).is_true()
	assert_bool(_player.controls_enabled).is_false()


func test_replay_after_its_over_starts_from_where_it_began() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	play_cutscene(_conversation, _player, SECTIONS, &"last")
	_press()
	assert_bool(_conversation.is_active()).is_false()
	_said.clear()

	assert_bool(_conversation.replay()).is_true()

	assert_array(_said).contains_exactly(["Last."])


func test_replay_with_nothing_played_yet_does_nothing() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)

	assert_bool(_conversation.replay()).is_false()
	assert_bool(_conversation.is_active()).is_false()


func test_the_replay_key_replays_the_last_cutscene() -> void:
	_build()
	var keys: CutsceneKeys = CutsceneKeys.new()
	_player.get_parent().add_child(keys)
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	assert_bool(keys.replay()).is_false()
	play_cutscene(_conversation, _player, "heron: One.\nheron: Two.")
	_press()
	_said.clear()

	await press(runner, String(CutsceneKeys.REPLAY_ACTION))

	assert_array(_said).contains_exactly(["One."])


func test_it_says_where_in_the_script_it_is() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)

	play_cutscene(_conversation, _player, "# A comment.\nheron: One.\nheron: Two.")
	_press()

	assert_str(_conversation.where()).is_equal("test.dlg, line 3")


func test_reading_a_file_again_gives_a_fresh_copy_and_keeps_it() -> void:
	var first: DialogueTree = DialogueLibrary.find(&"heron")

	var fresh: DialogueTree = DialogueLibrary.reread(&"heron")

	assert_object(fresh).is_not_null()
	assert_object(fresh).is_not_same(first)
	assert_array(fresh.errors).is_empty()
	assert_object(DialogueLibrary.find(&"heron")).is_same(fresh)
	assert_object(DialogueLibrary.reread(&"no_such_file")).is_null()


# The player, a conversation and a HUD. Called at the start of each test, so
# everything is made (and freed) inside it.
func _build() -> void:
	_said = PackedStringArray()
	_player = new_player_3d_on_floor()
	_conversation = new_conversation(_player)
	_hud = new_hud_3d(_player)
	_conversation.line_said.connect(func(_speaker: Person) -> void:
		_said.append(_line_showing()))


# Presses Interact past any typing: on to the next line, or picks the choice.
func _press() -> void:
	var box: DialogueBox = _hud.get_node("%DialogueBox") as DialogueBox
	if box.is_typing():
		box.finish_typing()
	_conversation.press()


# The words of the line the dialogue box is showing.
func _line_showing() -> String:
	return (_hud.get_node("%DialogueBox") as DialogueBox).line_text()
