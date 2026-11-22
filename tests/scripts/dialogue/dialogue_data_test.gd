extends GameTestSuite
## Checks every conversation and file of remarks written in data/dialogue,
## so a typo in a script fails here (and in CI) rather than in the middle of
## a talk.

## Every moment the game asks the lantern to react to.
const MOMENTS: Array[StringName] = [&"returned", &"remembered", &"caught",
		&"morning", &"hove_to", &"supper", &"dim", &"far_light", &"island", &"pulled_out",
		&"crab_killed"]


func test_there_are_conversations_to_check() -> void:
	assert_array(DialogueLibrary.all_ids()).contains([&"heron", &"lantern", &"intro"])
	assert_array(DialogueLibrary.all_ids()).contains(DialogueLibrary.REMARK_FILES)


func test_every_conversation_reads_without_mistakes() -> void:
	for id: StringName in DialogueLibrary.all_ids():
		var tree: DialogueTree = _read(id)
		assert_array(tree.errors) \
				.override_failure_message("%s.dlg: %s" % [id, ", ".join(tree.errors)]) \
				.is_empty()
		if not DialogueLibrary.is_remarks(id):
			assert_bool(tree.has_section(DialogueTree.START)) \
					.override_failure_message("%s.dlg has no '~ start'" % id).is_true()


func test_the_lantern_has_something_to_say_at_every_moment() -> void:
	for moment: StringName in MOMENTS:
		assert_array(Array(moment_lines(moment))) \
				.override_failure_message("moments.dlg: nothing [on %s]" % moment) \
				.is_not_empty()


func test_every_remark_has_somebody_saying_something() -> void:
	for id: StringName in DialogueLibrary.REMARK_FILES:
		for remark: Remark in Remark.all_in(_read(id)):
			assert_array(remark.speakers) \
					.override_failure_message("%s.dlg: '%s' says nothing" % [id, remark.section]) \
					.is_not_empty()


func test_the_chatter_has_remarks_for_night_and_morning() -> void:
	var state: DialogueState = DialogueState.new()
	var here: Dictionary[StringName, Vector3] = {&"heron": Vector3.ZERO}
	for time: StringName in [&"night", &"morning"]:
		state.reset()
		state.set_flag(time)
		var picked: Remark = RemarkPicker.new().pick(DialogueLibrary.remarks(&"ambient"), here,
				state, 0.0)
		assert_object(picked).override_failure_message("nothing to say at %s" % time) \
				.is_not_null()


func test_everyone_who_speaks_is_somebody_in_the_catalog() -> void:
	var catalog: Catalog = Catalog.load_default()
	for id: StringName in DialogueLibrary.all_ids():
		for speaker: StringName in _read(id).speakers():
			assert_object(catalog.find_person(speaker)) \
					.override_failure_message("%s.dlg: nobody is called '%s'" % [id, speaker]) \
					.is_not_null()


func test_the_crew_have_names_and_voices() -> void:
	var catalog: Catalog = Catalog.load_default()
	for id: StringName in [&"heron", &"lantern"]:
		var person: Person = catalog.find_person(id)
		assert_str(person.display_name).is_not_empty()
		assert_float(person.voice_pitch).is_greater(0.0)
	# The crew aren't the old restaurant's customers.
	assert_bool(catalog.people.has(catalog.find_person(&"heron"))).is_false()


func test_the_library_finds_a_conversation_and_keeps_it() -> void:
	var first: DialogueTree = DialogueLibrary.find(&"heron")

	assert_object(first).is_not_null()
	assert_str(String(first.id)).is_equal("heron")
	assert_object(DialogueLibrary.find(&"heron")).is_same(first)


func test_the_heron_greets_you_differently_once_youve_met() -> void:
	var state: DialogueState = DialogueState.new()
	state.set_fact(&"night", func() -> int: return 1)
	var runner: DialogueRunner = DialogueRunner.new()
	var said: PackedStringArray = PackedStringArray()
	runner.line_shown.connect(func(line: DialogueStep) -> void: said.append(line.text))

	runner.start(_read(&"heron"), state)
	var first_words: String = said[0]
	runner.stop()
	state.set_flag(&"met_heron")
	said.clear()
	runner.start(_read(&"heron"), state)

	assert_str(said[0]).is_not_equal(first_words)


func test_the_lantern_brings_up_a_fish_he_didnt_see_once() -> void:
	var state: DialogueState = DialogueState.new()
	state.set_flag(&"news_fish")
	var runner: DialogueRunner = DialogueRunner.new()
	var said: PackedStringArray = PackedStringArray()
	runner.line_shown.connect(func(line: DialogueStep) -> void: said.append(line.text))

	runner.start(_read(&"lantern"), state)

	assert_str(said[0]).contains("fish")
	assert_bool(state.is_set(&"news_fish")).is_false()


func _read(id: StringName) -> DialogueTree:
	var path: String = "%s/%s%s" % [DialogueLibrary.FOLDER, id, DialogueLibrary.ENDING]
	return DialogueScript.parse(FileAccess.get_file_as_string(path), id,
			DialogueLibrary.is_remarks(id))
