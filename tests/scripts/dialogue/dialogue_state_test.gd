extends GameTestSuite
## Tests for what conversations remember (flags), what they can ask the game
## (facts), and the conditions written against them.


func test_a_flag_never_set_is_zero() -> void:
	var state: DialogueState = DialogueState.new()

	assert_int(state.value(&"met_heron")).is_equal(0)
	assert_bool(state.is_set(&"met_heron")).is_false()


func test_flags_are_set_added_to_and_cleared() -> void:
	var state: DialogueState = DialogueState.new()

	state.set_flag(&"met_heron")
	state.add(&"visits", 2)
	state.add(&"visits")
	assert_int(state.value(&"met_heron")).is_equal(1)
	assert_int(state.value(&"visits")).is_equal(3)

	state.clear(&"met_heron")
	assert_bool(state.is_set(&"met_heron")).is_false()


func test_flag_changed_fires_only_on_a_real_change() -> void:
	var state: DialogueState = DialogueState.new()
	var changes: Array[int] = []
	state.flag_changed.connect(func(_flag: StringName, value: int) -> void: changes.append(value))

	state.set_flag(&"met_heron")
	state.set_flag(&"met_heron")
	state.clear(&"met_heron")

	assert_array(changes).contains_exactly([1, 0])


func test_a_fact_is_asked_each_time() -> void:
	var state: DialogueState = DialogueState.new()
	var night: Array[bool] = [true]
	state.set_fact(&"night", func() -> int: return 1 if night[0] else 0)

	assert_bool(state.is_set(&"night")).is_true()
	night[0] = false
	assert_bool(state.is_set(&"night")).is_false()


func test_a_fact_cant_be_set_by_a_script() -> void:
	var state: DialogueState = DialogueState.new()
	state.set_fact(&"night", func() -> int: return 1)

	await assert_error(func() -> void: state.set_flag(&"night", 0)) \
			.is_push_error(any_string())

	assert_bool(state.is_set(&"night")).is_true()


func test_flags_save_and_come_back_but_facts_arent_saved() -> void:
	var state: DialogueState = DialogueState.new()
	state.set_flag(&"met_heron")
	state.add(&"talked.heron", 3)
	state.set_fact(&"night", func() -> int: return 1)

	var data: Dictionary = state.to_dict()
	# As a save file does: through JSON, where whole numbers come back as floats.
	var parsed: Variant = JSON.parse_string(JSON.stringify(data))
	var read: Dictionary = parsed
	var other: DialogueState = DialogueState.new()
	other.restore(read)

	assert_bool(data.has("night")).is_false()
	assert_int(other.value(&"met_heron")).is_equal(1)
	assert_int(other.value(&"talked.heron")).is_equal(3)


func test_reset_forgets_flags_and_keeps_facts() -> void:
	var state: DialogueState = DialogueState.new()
	state.set_flag(&"met_heron")
	state.set_fact(&"night", func() -> int: return 1)

	state.reset()

	assert_bool(state.is_set(&"met_heron")).is_false()
	assert_bool(state.is_set(&"night")).is_true()


func test_conditions_read_flags_nots_and_comparisons(condition: String, expected: bool,
		test_parameters: Array = [
			["met_heron", true],
			["not met_heron", false],
			["missing", false],
			["not missing", true],
			["visits >= 2", true],
			["visits > 2", false],
			["visits == 2", true],
			["visits != 2", false],
			["visits < 3", true],
			["visits <= 1", false],
			["met_heron and visits >= 2", true],
			["met_heron and not missing and visits == 2", true],
			["met_heron and missing", false],
			["talked.heron == 0", true],
			["", true],
		]) -> void:
	var state: DialogueState = DialogueState.new()
	state.set_flag(&"met_heron")
	state.set_flag(&"visits", 2)

	assert_bool(DialogueCondition.holds(condition, state)).is_equal(expected)


func test_conditions_that_cant_be_read_are_reported_and_never_hold(condition: String,
		test_parameters: Array = [
			["visits more than 2"],
			["visits >= two"],
			["not"],
			["met_heron and"],
			["Met_Heron"],
			["2visits"],
			["a or b"],
		]) -> void:
	var state: DialogueState = DialogueState.new()

	assert_str(DialogueCondition.error_in(condition)).is_not_empty()
	assert_bool(DialogueCondition.holds(condition, state)).is_false()


func test_a_good_condition_has_no_error() -> void:
	assert_str(DialogueCondition.error_in("met_heron and visits >= 2")).is_empty()
	assert_str(DialogueCondition.error_in("")).is_not_empty()
