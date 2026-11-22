extends GameTestSuite
## Tests for reading a conversation written as text: every kind of statement,
## and mistakes reported with their line numbers instead of crashing.


func test_a_line_has_its_speaker_words_and_tag() -> void:
	var tree: DialogueTree = DialogueScript.parse("~ start\nheron: Rough night. [gruff]")

	assert_array(tree.errors).is_empty()
	var line: DialogueStep = tree.steps[0]
	assert_int(line.kind).is_equal(DialogueStep.Kind.LINE)
	assert_str(String(line.speaker)).is_equal("heron")
	assert_str(line.text).is_equal("Rough night.")
	assert_str(String(line.tag)).is_equal("gruff")
	assert_int(line.line_number).is_equal(2)


func test_a_line_keeps_colons_and_brackets_that_are_part_of_its_words() -> void:
	var tree: DialogueTree = DialogueScript.parse(
			"heron: Two things: rope, and tea [the good tea] for later.")

	assert_array(tree.errors).is_empty()
	assert_str(tree.steps[0].text).is_equal("Two things: rope, and tea [the good tea] for later.")
	assert_str(String(tree.steps[0].tag)).is_empty()


func test_a_line_with_no_speaker_is_a_narrator() -> void:
	var tree: DialogueTree = DialogueScript.parse(": The stove ticks.")

	assert_array(tree.errors).is_empty()
	assert_str(String(tree.steps[0].speaker)).is_empty()
	assert_str(tree.steps[0].text).is_equal("The stove ticks.")


func test_statements_before_any_section_are_the_start() -> void:
	var tree: DialogueTree = DialogueScript.parse("heron: Hm.")

	assert_bool(tree.has_section(DialogueTree.START)).is_true()
	assert_int(tree.sections[DialogueTree.START]).is_equal(0)


func test_comments_and_blank_lines_are_skipped() -> void:
	var tree: DialogueTree = DialogueScript.parse("# who's this\n\n~ start\n  heron: Hm.  \n")

	assert_array(tree.errors).is_empty()
	# The line, then the end of its section.
	assert_int(tree.steps.size()).is_equal(2)


func test_a_choice_has_its_words_and_where_it_leads() -> void:
	var tree: DialogueTree = DialogueScript.parse(
			"~ start\n- Where are we headed? -> heading\n- Never mind. -> END\n~ heading\nheron: North.")

	assert_array(tree.errors).is_empty()
	assert_int(tree.steps[0].kind).is_equal(DialogueStep.Kind.CHOICE)
	assert_str(tree.steps[0].text).is_equal("Where are we headed?")
	assert_str(String(tree.steps[0].target)).is_equal("heading")
	assert_str(String(tree.steps[1].target)).is_equal("END")


func test_each_section_ends_the_conversation_rather_than_running_on() -> void:
	var tree: DialogueTree = DialogueScript.parse("~ start\nheron: One.\n~ other\nheron: Two.")

	var end: DialogueStep = tree.steps[1]
	assert_int(end.kind).is_equal(DialogueStep.Kind.JUMP)
	assert_str(String(end.target)).is_equal("END")
	assert_int(tree.sections[&"other"]).is_equal(2)


func test_a_guard_belongs_to_the_next_statement_only() -> void:
	var tree: DialogueTree = DialogueScript.parse(
			"? met_heron and day >= 2\nheron: You again.\n? else\nheron: Who are you?\nheron: Hm.")

	assert_array(tree.errors).is_empty()
	assert_str(tree.steps[0].guard).is_equal("met_heron and day >= 2")
	assert_bool(tree.steps[1].is_else).is_true()
	assert_str(tree.steps[2].guard).is_empty()
	assert_bool(tree.steps[2].is_else).is_false()


func test_set_and_clear_change_flags() -> void:
	var tree: DialogueTree = DialogueScript.parse(
			"set met\nset visits + 2\nset visits - 1\nset mood = 3\nclear news_fish")

	assert_array(tree.errors).is_empty()
	assert_int(tree.steps[0].amount).is_equal(1)
	assert_int(tree.steps[0].change).is_equal(DialogueStep.Change.TO)
	assert_int(tree.steps[1].change).is_equal(DialogueStep.Change.BY)
	assert_int(tree.steps[1].amount).is_equal(2)
	assert_int(tree.steps[2].amount).is_equal(-1)
	assert_int(tree.steps[3].change).is_equal(DialogueStep.Change.TO)
	assert_int(tree.steps[3].amount).is_equal(3)
	assert_str(String(tree.steps[4].flag)).is_equal("news_fish")
	assert_int(tree.steps[4].amount).is_equal(0)


func test_a_cue_has_its_name_and_the_words_after_it() -> void:
	var tree: DialogueTree = DialogueScript.parse("@shot stove_nook slowly")

	assert_array(tree.errors).is_empty()
	assert_int(tree.steps[0].kind).is_equal(DialogueStep.Kind.CUE)
	assert_str(String(tree.steps[0].cue)).is_equal("shot")
	assert_array(tree.steps[0].args).contains_exactly(["stove_nook", "slowly"])


func test_a_jump_to_a_section_that_isnt_there_is_reported_with_its_line() -> void:
	var tree: DialogueTree = DialogueScript.parse("~ start\nheron: Hm.\n-> nowhere")

	assert_int(tree.errors.size()).is_equal(1)
	assert_str(tree.errors[0]).contains("line 3").contains("nowhere")


func test_a_choice_to_a_section_that_isnt_there_is_reported() -> void:
	var tree: DialogueTree = DialogueScript.parse("- Hello? -> nowhere")

	assert_int(tree.errors.size()).is_equal(1)
	assert_str(tree.errors[0]).contains("line 1")


func test_a_line_that_cant_be_read_is_reported_and_the_rest_still_reads() -> void:
	var tree: DialogueTree = DialogueScript.parse("~ start\nwhat is this\nheron: Hm.")

	assert_int(tree.errors.size()).is_equal(1)
	assert_str(tree.errors[0]).contains("line 2")
	assert_str(tree.steps[0].text).is_equal("Hm.")


func test_a_guard_with_nothing_after_it_is_reported() -> void:
	var tree: DialogueTree = DialogueScript.parse("~ start\nheron: Hm.\n? met_heron")

	assert_int(tree.errors.size()).is_equal(1)
	assert_str(tree.errors[0]).contains("line 3")


func test_a_condition_that_cant_be_read_is_reported() -> void:
	var tree: DialogueTree = DialogueScript.parse("? visits more than 2\nheron: Hm.")

	assert_int(tree.errors.size()).is_equal(1)
	assert_str(tree.errors[0]).contains("line 1")


func test_two_sections_with_one_name_is_reported() -> void:
	var tree: DialogueTree = DialogueScript.parse("~ start\nheron: A.\n~ start\nheron: B.")

	assert_int(tree.errors.size()).is_equal(1)
	assert_str(tree.errors[0]).contains("line 3")


func test_a_script_with_sections_but_no_start_is_reported() -> void:
	var tree: DialogueTree = DialogueScript.parse("~ later\nheron: A.")

	assert_int(tree.errors.size()).is_equal(1)
	assert_str(tree.errors[0]).contains("start")


func test_speakers_lists_everyone_who_talks_once() -> void:
	var tree: DialogueTree = DialogueScript.parse("heron: A.\nlantern: B.\nheron: C.\n: D.")

	assert_array(tree.speakers()).contains_exactly([&"heron", &"lantern"])
