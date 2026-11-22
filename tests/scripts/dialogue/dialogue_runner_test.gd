extends GameTestSuite
## Tests for walking a conversation: lines in order, choices that branch,
## guards and their else, flags, cues, and ending.

var _state: DialogueState
var _runner: DialogueRunner
## What was said, in order, as "speaker: words".
var _said: PackedStringArray
var _cues: PackedStringArray
var _finished: int


func before_test() -> void:
	_state = DialogueState.new()
	_runner = DialogueRunner.new()
	_said = PackedStringArray()
	_cues = PackedStringArray()
	_finished = 0
	_runner.line_shown.connect(func(line: DialogueStep) -> void:
		_said.append("%s: %s" % [line.speaker, line.text]))
	_runner.cue.connect(func(name: StringName, args: PackedStringArray) -> void:
		_cues.append("%s %s" % [name, " ".join(args)]))
	_runner.finished.connect(func() -> void: _finished += 1)


func test_lines_come_one_at_a_time_and_then_it_finishes() -> void:
	_start("heron: One.\nheron: Two.")

	assert_array(_said).contains_exactly(["heron: One."])
	_runner.advance()
	assert_array(_said).contains_exactly(["heron: One.", "heron: Two."])
	assert_bool(_runner.is_active()).is_true()
	_runner.advance()

	assert_bool(_runner.is_active()).is_false()
	assert_int(_finished).is_equal(1)


func test_a_choice_carries_on_from_the_section_it_leads_to() -> void:
	_start("heron: Well?\n- Weather? -> weather\n- Heading? -> heading\n"
			+ "~ weather\nheron: Wet.\n~ heading\nheron: North.")
	_runner.advance()

	assert_bool(_runner.is_choosing()).is_true()
	assert_int(_runner.choices.size()).is_equal(2)
	_runner.choose(1)

	assert_str(_said[_said.size() - 1]).is_equal("heron: North.")
	_runner.advance()
	assert_int(_finished).is_equal(1)


func test_advance_does_nothing_while_a_choice_is_waiting() -> void:
	_start("- Yes -> END\n- No -> END")

	_runner.advance()

	assert_bool(_runner.is_choosing()).is_true()
	assert_int(_finished).is_equal(0)


func test_a_choice_to_end_finishes() -> void:
	_start("- Never mind. -> END")

	_runner.choose(0)

	assert_int(_finished).is_equal(1)


func test_a_choice_out_of_range_is_ignored() -> void:
	_start("- Yes -> END")

	_runner.choose(3)

	assert_bool(_runner.is_choosing()).is_true()


func test_a_guard_skips_only_the_statement_after_it() -> void:
	_start("? met_heron\nheron: You again.\nheron: Hm.")

	assert_array(_said).contains_exactly(["heron: Hm."])


func test_a_guard_that_holds_lets_its_statement_run() -> void:
	_state.set_flag(&"met_heron")
	_start("? met_heron\nheron: You again.\nheron: Hm.")

	assert_array(_said).contains_exactly(["heron: You again."])


func test_else_runs_only_when_the_guard_before_it_failed() -> void:
	_start("? met_heron\nheron: You again.\n? else\nheron: Who are you?")
	assert_array(_said).contains_exactly(["heron: Who are you?"])

	before_test()
	_state.set_flag(&"met_heron")
	_start("? met_heron\nheron: You again.\n? else\nheron: Who are you?")
	_runner.advance()
	assert_array(_said).contains_exactly(["heron: You again."])


func test_a_guard_on_a_jump_branches_a_whole_section() -> void:
	_state.set_flag(&"night")
	_start("? night\n-> dark\nheron: Morning.\n~ dark\nheron: Evening.")

	assert_array(_said).contains_exactly(["heron: Evening."])


func test_set_add_and_clear_change_the_flags() -> void:
	_state.set_flag(&"news_fish")
	_start("set met_heron\nset visits + 2\nset visits + 1\nclear news_fish\nheron: Hm.")

	assert_int(_state.value(&"met_heron")).is_equal(1)
	assert_int(_state.value(&"visits")).is_equal(3)
	assert_int(_state.value(&"news_fish")).is_equal(0)


func test_a_flag_set_earlier_changes_a_guard_later_in_the_same_talk() -> void:
	_start("set asked\n? asked\nheron: You asked.")

	assert_array(_said).contains_exactly(["heron: You asked."])


func test_choices_whose_guard_fails_are_left_out() -> void:
	_state.set_flag(&"asked_heading")
	_start("- Weather? -> END\n? not asked_heading\n- Heading? -> END\n- Bye. -> END")

	var texts: PackedStringArray = PackedStringArray()
	for choice: DialogueStep in _runner.choices:
		texts.append(choice.text)
	assert_array(texts).contains_exactly(["Weather?", "Bye."])


func test_a_menu_with_no_choices_left_is_skipped() -> void:
	_start("? never\n- Hidden -> END\nheron: Nothing to ask, then.")

	assert_bool(_runner.is_choosing()).is_false()
	assert_array(_said).contains_exactly(["heron: Nothing to ask, then."])


func test_a_cue_is_passed_on_with_its_words() -> void:
	_start("@shot stove_nook\nheron: Hm.\n@shot free")

	assert_array(_cues).contains_exactly(["shot stove_nook"])
	_runner.advance()
	assert_array(_cues).contains_exactly(["shot stove_nook", "shot free"])


func test_starting_at_a_named_section() -> void:
	var tree: DialogueTree = DialogueScript.parse("heron: Start.\n~ other\nheron: Other.")

	assert_bool(_runner.start(tree, _state, &"other")).is_true()

	assert_array(_said).contains_exactly(["heron: Other."])


func test_starting_at_a_section_that_isnt_there_starts_nothing() -> void:
	var tree: DialogueTree = DialogueScript.parse("heron: Start.")

	assert_bool(_runner.start(tree, _state, &"nowhere")).is_false()
	assert_bool(_runner.is_active()).is_false()


func test_a_script_that_jumps_in_a_circle_ends_instead_of_hanging() -> void:
	var tree: DialogueTree = DialogueScript.parse("~ start\n-> again\n~ again\n-> start")

	await assert_error(func() -> void: _runner.start(tree, _state)) \
			.is_push_error(any_string())

	assert_bool(_runner.is_active()).is_false()
	assert_int(_finished).is_equal(1)


func test_stop_ends_it_once() -> void:
	_start("heron: One.\nheron: Two.")

	_runner.stop()
	_runner.stop()

	assert_int(_finished).is_equal(1)
	assert_object(_runner.line).is_null()


func _start(script: String) -> void:
	var tree: DialogueTree = DialogueScript.parse(script)
	assert_array(tree.errors).is_empty()
	_runner.start(tree, _state)


func test_a_cue_somebody_holds_stops_the_script_until_its_released() -> void:
	_hold_on(&"wait")
	_start("heron: One.\n@wait 1.0\nheron: Two.")
	_runner.advance()

	assert_bool(_runner.is_held()).is_true()
	assert_array(_said).contains_exactly(["heron: One."])

	_runner.release()

	assert_bool(_runner.is_held()).is_false()
	assert_array(_said).contains_exactly(["heron: One.", "heron: Two."])


func test_pressing_on_does_nothing_while_a_cue_holds_the_script() -> void:
	_hold_on(&"wait")
	_start("@wait 1.0\nheron: After.")

	_runner.advance()
	_runner.advance()

	assert_bool(_runner.is_held()).is_true()
	assert_array(_said).is_empty()


func test_two_holds_need_two_releases() -> void:
	_hold_on(&"wait")
	_hold_on(&"wait")
	_start("@wait 1.0\nheron: After.")

	_runner.release()
	assert_array(_said).is_empty()
	_runner.release()

	assert_array(_said).contains_exactly(["heron: After."])


func test_a_hold_released_straight_away_carries_on_without_repeating_anything() -> void:
	_runner.cue.connect(func(_name: StringName, _args: PackedStringArray) -> void:
		_runner.hold()
		_runner.release())
	_start("@wait 1.0\nheron: After.\n@wait 1.0\nheron: Last.")
	_runner.advance()

	assert_array(_said).contains_exactly(["heron: After.", "heron: Last."])
	assert_array(_cues).contains_exactly(["wait 1.0", "wait 1.0"])


func test_release_all_lets_go_of_every_hold_at_once() -> void:
	_hold_on(&"wait")
	_hold_on(&"wait")
	_start("@wait 1.0\nheron: After.")

	_runner.release_all()

	assert_bool(_runner.is_held()).is_false()
	assert_array(_said).contains_exactly(["heron: After."])


func test_stopping_forgets_its_holds_so_the_next_script_isnt_held() -> void:
	_hold_on(&"wait")
	_start("@wait 1.0\nheron: After.")

	_runner.stop()
	_runner.release()
	_start("heron: Fresh.")

	assert_int(_finished).is_equal(1)
	assert_bool(_runner.is_held()).is_false()
	assert_array(_said).contains_exactly(["heron: Fresh."])


func test_a_release_with_nothing_held_does_nothing() -> void:
	_start("heron: One.\nheron: Two.")

	_runner.release()
	_runner.release_all()

	assert_array(_said).contains_exactly(["heron: One."])


func test_it_knows_which_section_and_line_it_has_reached() -> void:
	var tree: DialogueTree = DialogueScript.parse(
			"heron: Start.\n-> second\n~ second\nheron: Second.\nheron: More.")
	assert_str(String(_runner.section())).is_empty()

	_runner.start(tree, _state)
	assert_str(String(_runner.section())).is_equal("start")
	assert_int(_runner.line_number()).is_equal(1)

	_runner.advance()
	assert_str(String(_runner.section())).is_equal("second")
	assert_int(_runner.line_number()).is_equal(4)

	_runner.advance()
	assert_str(String(_runner.section())).is_equal("second")
	assert_int(_runner.line_number()).is_equal(5)


# Makes the runner hold once each time the script gives the cue [param name].
func _hold_on(name: StringName) -> void:
	var holder: Callable = func(cue: StringName, _args: PackedStringArray) -> void:
		if cue == name:
			_runner.hold()
	_runner.cue.connect(holder)
